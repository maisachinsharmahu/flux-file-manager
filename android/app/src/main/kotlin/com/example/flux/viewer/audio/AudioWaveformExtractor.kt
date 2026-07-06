package com.example.flux.viewer.audio

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import java.io.File
import java.nio.ByteBuffer
import kotlin.math.abs

/**
 * AudioWaveformExtractor — extracts amplitude points from audio files (MP3, WAV, M4A, etc.).
 *
 * Runs a high-performance demux-decode loop using MediaExtractor and MediaCodec.
 * Downsamples PCM amplitudes to a clean IntArray of 256 bars.
 *
 * Rules (doc2, Ch. 16):
 *   - Zero external libraries — strictly standard Android APIs (Rule 3).
 *   - Runs on background threads to prevent UI lag.
 */
object AudioWaveformExtractor {

    /**
     * Decode file and downsample PCM into a 256-bar amplitude spectrum.
     * Processes on background dispatcher. Returns IntArray of 256 peaks.
     */
    fun extract(filePath: String, targetBarCount: Int = 256): IntArray {
        val file = File(filePath)
        if (!file.exists()) return IntArray(targetBarCount)

        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        val rawAmplitudes = ArrayList<Int>(1024)

        try {
            extractor.setDataSource(file.absolutePath)
            
            // 1. Locate audio track
            var audioTrackIndex = -1
            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                val mime = f.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("audio/")) {
                    audioTrackIndex = i
                    format = f
                    extractor.selectTrack(i)
                    break
                }
            }

            if (audioTrackIndex == -1 || format == null) {
                return IntArray(targetBarCount)
            }

            // 2. Configure MediaCodec decoder
            val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
            decoder = MediaCodec.createDecoderByType(mime)
            decoder.configure(format, null, null, 0)
            decoder.start()

            // 3. Demux-Decode loop
            val bufferInfo = MediaCodec.BufferInfo()
            var inputEof = false
            var outputEof = false

            // Track sample statistics
            var maxAmplitude = 0

            // Speed optimization: limit processing of extremely long files to first 5 minutes
            val durationUs = if (format.containsKey(MediaFormat.KEY_DURATION)) format.getLong(MediaFormat.KEY_DURATION) else 0L
            val limitUs = 5 * 60 * 1000 * 1000L // 5 mins
            
            while (!outputEof && rawAmplitudes.size < 10000) { // Safety ceiling to avoid OOM
                // Feed input buffers to decoder
                if (!inputEof) {
                    val inputBufferIndex = decoder.dequeueInputBuffer(1000) // 1ms wait
                    if (inputBufferIndex >= 0) {
                        val inputBuffer = decoder.getInputBuffer(inputBufferIndex) ?: break
                        val sampleSize = extractor.readSampleData(inputBuffer, 0)
                        
                        if (sampleSize < 0 || (durationUs > limitUs && extractor.sampleTime > limitUs)) {
                            // EOF or limit hit
                            decoder.queueInputBuffer(
                                inputBufferIndex, 0, 0, 0,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM
                            )
                            inputEof = true
                        } else {
                            decoder.queueInputBuffer(
                                inputBufferIndex, 0, sampleSize, extractor.sampleTime, 0
                            )
                            extractor.advance()
                        }
                    }
                }

                // Retrieve decoded PCM output buffers
                val outputBufferIndex = decoder.dequeueOutputBuffer(bufferInfo, 1000)
                if (outputBufferIndex >= 0) {
                    val outputBuffer = decoder.getOutputBuffer(outputBufferIndex)
                    if (outputBuffer != null && bufferInfo.size > 0) {
                        // Calculate peak amplitude in this chunk
                        val pcmPeak = calculatePcmPeak(outputBuffer, bufferInfo.size)
                        rawAmplitudes.add(pcmPeak)
                        if (pcmPeak > maxAmplitude) maxAmplitude = pcmPeak
                    }

                    decoder.releaseOutputBuffer(outputBufferIndex, false)

                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        outputEof = true
                    }
                } else if (outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    // Decoder channel format changed
                }
            }

        } catch (e: Exception) {
            android.util.Log.e("WaveformExtractor", "Decoding failed: ${e.message}", e)
        } finally {
            try {
                decoder?.stop()
                decoder?.release()
            } catch (_: Exception) {}
            try {
                extractor.release()
            } catch (_: Exception) {}
        }

        // 4. Downsample raw values to exactly targetBarCount points
        return downsample(rawAmplitudes, targetBarCount)
    }

    /**
     * Compute maximum absolute amplitude in 16-bit PCM sample buffer.
     * 16-bit PCM samples are stored as pairs of bytes (little-endian).
     */
    private fun calculatePcmPeak(buffer: ByteBuffer, size: Int): Int {
        var peak = 0
        // Sample every 4th short to speed up calculations
        for (i in 0 until size step 8) {
            if (i + 1 >= buffer.limit()) break
            
            // Read Little Endian 16-bit short value
            val b1 = buffer.get(i).toInt()
            val b2 = buffer.get(i + 1).toInt()
            val value = abs((b1 and 0xFF) or (b2 shl 8))
            
            if (value > peak) peak = value
        }
        return peak
    }

    /**
     * Downsample raw amplitude array list to target size using average/max values in windows.
     */
    private fun downsample(raw: ArrayList<Int>, targetSize: Int): IntArray {
        val result = IntArray(targetSize)
        if (raw.isEmpty()) return result

        val windowSize = raw.size.toDouble() / targetSize
        for (i in 0 until targetSize) {
            val start = (i * windowSize).toInt().coerceIn(0, raw.size - 1)
            val end = ((i + 1) * windowSize).toInt().coerceIn(0, raw.size)
            
            var sum = 0
            var count = 0
            for (j in start until end) {
                sum += raw[j]
                count++
            }
            // Use average amplitude of this window, fallback to raw[start] if empty
            val avg = if (count > 0) sum / count else raw[start]
            
            // Scale value to a normalized 0-100 integer range for easier UI painting
            result[i] = (avg / 327.67).toInt().coerceIn(2, 100) // 32767 is max amplitude in 16-bit
        }
        return result
    }
}
