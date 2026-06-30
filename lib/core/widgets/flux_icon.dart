import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum FluxIconType {
  cleanOff,
  cleanOn,
  cloudOff,
  cloudOn,
  downOff,
  downOn,
  dropbox,
  folderOff,
  folderOn,
  folderColor,
  homeOff,
  homeOn,
  facebook,
  favoriteColor,
  adobeReader,
  apk,
  audioColor,
  audioOn,
  broomColor,
  databaseOn,
  documentOff,
  documentColor,
  documentOn,
  downloadUpdatesOff,
  favoriteFolder,
  fileColor,
  forwardOn,
  googleDrive,
  gridViewOff,
  happyFileOn,
  imageDocumentOn,
  imageFileColor,
  leftArrowOff,
  linkedin,
  menuListOff,
  menuVerticalOff,
  onedrive,
  pictureOff,
  plusMathOff,
  privateFolderOff,
  searchOff,
  storageOn,
  timeMachineOff,
  trashOff,
  uploadOff,
  videoFileColor,
  videoFileOn,
  waze,
  yahooMail,
}

class FluxIcon extends StatelessWidget {
  final FluxIconType icon;
  final double? size;
  final Color? color;

  const FluxIcon(this.icon, {Key? key, this.size, this.color})
    : super(key: key);

  String get _assetPath {
    switch (icon) {
      case FluxIconType.cleanOff:
        return 'assets/icons/Property 1=Clean, Fill=off, Color=off.svg';
      case FluxIconType.cleanOn:
        return 'assets/icons/Property 1=Clean, Fill=on, Color=off.svg';
      case FluxIconType.cloudOff:
        return 'assets/icons/Property 1=Cloud, Fill=off, Color=off.svg';
      case FluxIconType.cloudOn:
        return 'assets/icons/Property 1=Cloud, Fill=on, Color=off.svg';
      case FluxIconType.downOff:
        return 'assets/icons/Property 1=Down, Fill=off, Color=off.svg';
      case FluxIconType.downOn:
        return 'assets/icons/Property 1=Down, Fill=on, Color=off.svg';
      case FluxIconType.dropbox:
        return 'assets/icons/Property 1=Dropbox, Fill=on, Color=on.svg';
      case FluxIconType.folderOff:
        return 'assets/icons/Property 1=Folder, Fill=off, Color=off.svg';
      case FluxIconType.folderOn:
        return 'assets/icons/Property 1=Folder, Fill=on, Color=off.svg';
      case FluxIconType.folderColor:
        return 'assets/icons/Property 1=Folder, Fill=on, Color=on.svg';
      case FluxIconType.homeOff:
        return 'assets/icons/Property 1=Home, Fill=off, Color=off.svg';
      case FluxIconType.homeOn:
        return 'assets/icons/Property 1=Home, Fill=on, Color=off.svg';
      case FluxIconType.facebook:
        return 'assets/icons/Property 1=icons8_Facebook_1 1, Fill=on, Color=on.svg';
      case FluxIconType.favoriteColor:
        return 'assets/icons/Property 1=icons8_Favorite 1, Fill=on, Color=on.svg';
      case FluxIconType.adobeReader:
        return 'assets/icons/Property 1=icons8_adobe_acrobat_reader 1, Fill=on, Color=on.svg';
      case FluxIconType.apk:
        return 'assets/icons/Property 1=icons8_apk 1, Fill=on, Color=on.svg';
      case FluxIconType.audioColor:
        return 'assets/icons/Property 1=icons8_audio_file 1, Fill=on, Color=on.svg';
      case FluxIconType.audioOn:
        return 'assets/icons/Property 1=icons8_audio_file_1 1, Fill=on, Color=off.svg';
      case FluxIconType.broomColor:
        return 'assets/icons/Property 1=icons8_broom_3 1, Fill=on, Color=on.svg';
      case FluxIconType.databaseOn:
        return 'assets/icons/Property 1=icons8_database 1, Fill=on, Color=off.svg';
      case FluxIconType.documentOff:
        return 'assets/icons/Property 1=icons8_document 1, Fill=off, Color=off.svg';
      case FluxIconType.documentColor:
        return 'assets/icons/Property 1=icons8_document_1 1, Fill=on, Color=on.svg';
      case FluxIconType.documentOn:
        return 'assets/icons/Property 1=icons8_document_3 1, Fill=on, Color=off.svg';
      case FluxIconType.downloadUpdatesOff:
        return 'assets/icons/Property 1=icons8_downloading_updates 1, Fill=off, Color=off.svg';
      case FluxIconType.favoriteFolder:
        return 'assets/icons/Property 1=icons8_favorite_folder 1, Fill=on, Color=on.svg';
      case FluxIconType.fileColor:
        return 'assets/icons/Property 1=icons8_file 1, Fill=on, Color=on.svg';
      case FluxIconType.forwardOn:
        return 'assets/icons/Property 1=icons8_forward 1, Fill=on, Color=off.svg';
      case FluxIconType.googleDrive:
        return 'assets/icons/Property 1=icons8_google_drive 1, Fill=on, Color=on.svg';
      case FluxIconType.gridViewOff:
        return 'assets/icons/Property 1=icons8_grid_2_1 1, Fill=off, Color=off.svg';
      case FluxIconType.happyFileOn:
        return 'assets/icons/Property 1=icons8_happy_file 1, Fill=on, Color=off.svg';
      case FluxIconType.imageDocumentOn:
        return 'assets/icons/Property 1=icons8_image_document 1, Fill=on, Color=off.svg';
      case FluxIconType.imageFileColor:
        return 'assets/icons/Property 1=icons8_image_file 1, Fill=on, Color=on.svg';
      case FluxIconType.leftArrowOff:
        return 'assets/icons/Property 1=icons8_left_arrow 1, Fill=off, Color=off.svg';
      case FluxIconType.linkedin:
        return 'assets/icons/Property 1=icons8_linkedin 1, Fill=on, Color=on.svg';
      case FluxIconType.menuListOff:
        return 'assets/icons/Property 1=icons8_menu_1 1, Fill=off, Color=off.svg';
      case FluxIconType.menuVerticalOff:
        return 'assets/icons/Property 1=icons8_menu_vertical_1 1, Fill=off, Color=off.svg';
      case FluxIconType.onedrive:
        return 'assets/icons/Property 1=icons8_microsoft_onedrive_2019 1, Fill=on, Color=on.svg';
      case FluxIconType.pictureOff:
        return 'assets/icons/Property 1=icons8_picture 1, Fill=off, Color=off.svg';
      case FluxIconType.plusMathOff:
        return 'assets/icons/Property 1=icons8_plus_math 1, Fill=off, Color=off.svg';
      case FluxIconType.privateFolderOff:
        return 'assets/icons/Property 1=icons8_private_folder 1, Fill=off, Color=off.svg';
      case FluxIconType.searchOff:
        return 'assets/icons/Property 1=icons8_search_2 1, Fill=off, Color=off.svg';
      case FluxIconType.storageOn:
        return 'assets/icons/Property 1=icons8_storage 1, Fill=on, Color=off.svg';
      case FluxIconType.timeMachineOff:
        return 'assets/icons/Property 1=icons8_time_machine 1, Fill=off, Color=off.svg';
      case FluxIconType.trashOff:
        return 'assets/icons/Property 1=icons8_trash 1, Fill=off, Color=off.svg';
      case FluxIconType.uploadOff:
        return 'assets/icons/Property 1=icons8_upload 1, Fill=off, Color=off.svg';
      case FluxIconType.videoFileColor:
        return 'assets/icons/Property 1=icons8_video_file 1, Fill=on, Color=on.svg';
      case FluxIconType.videoFileOn:
        return 'assets/icons/Property 1=icons8_video_file_2 1, Fill=on, Color=off.svg';
      case FluxIconType.waze:
        return 'assets/icons/Property 1=icons8_waze 1, Fill=on, Color=on.svg';
      case FluxIconType.yahooMail:
        return 'assets/icons/Property 1=icons8_yahoo_mail_app 1, Fill=on, Color=on.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
