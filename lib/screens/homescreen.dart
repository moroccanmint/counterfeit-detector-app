import 'package:cashguard/components/material_button_icon.dart';
import 'package:cashguard/components/transaction_popup.dart';
import 'package:cashguard/components/banknote_authenticator.dart';
import 'package:cashguard/components/loading_dialog.dart';
import 'package:cashguard/constants.dart';
import 'package:cashguard/controllers/application_controller.dart';
import 'package:cashguard/screens/learnmorescreen.dart';
import 'package:cashguard/screens/transactionscreen.dart';
import 'package:cashguard/screens/onboardingscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({Key? key}) : super(key: key);

  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  Interpreter? _interpreter;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _resizedImageBytes;
  Uint8List? _croppedImageBytes1;
  Uint8List? _croppedImageBytes2;
  Uint8List? _processedImageBytes1;
  Uint8List? _processedImageBytes2;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/model/model-7v2.tflite');
  }

  Future<List<double>> preprocessImage(cv.Mat cvImage) async {
    // Convert OpenCV image to Image package format
    img.Image image = img.Image.fromBytes(
      cvImage.cols,
      cvImage.rows,
      cvImage.data,
      format: img.Format.bgr,
    );

    // Resize the image to 299x299 if it's not already that size
    if (image.width != 299 || image.height != 299) {
      image = img.copyResize(image, width: 299, height: 299);
    }

    // Convert the image to a list of normalized pixel values
    List<double> pixelList = [];
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int pixel = image.getPixel(x, y);
        int r = img.getRed(pixel);
        int g = img.getGreen(pixel);
        int b = img.getBlue(pixel);

        // Normalize RGB values to [0, 1]
        pixelList.add(r / 255.0);
        pixelList.add(g / 255.0);
        pixelList.add(b / 255.0);
      }
    }

    // Reshape the list to add an extra dimension (equivalent to np.expand_dims(img_array, axis=0))
    // This creates a 4D list with shape [1, 299, 299, 3]
    List<List<List<List<double>>>> expandedPixelList = [
      List.generate(
        299,
        (y) => List.generate(
          299,
          (x) => [
            pixelList[(y * 299 + x) * 3],
            pixelList[(y * 299 + x) * 3 + 1],
            pixelList[(y * 299 + x) * 3 + 2],
          ],
        ),
      )
    ];

    // Flatten the 4D list back into a 1D list for easier handling
    List<double> flattenedExpandedList = expandedPixelList
        .expand((plane) => plane)
        .expand((row) => row)
        .expand((pixel) => pixel)
        .toList();

    return flattenedExpandedList;
  }

  Future<void> processAndPredictImage(
      String imagePath, BuildContext context) async {
    //Loading animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const LoadingDialog(),
    );

    // Add a small delay to ensure the loader appears
    await Future.delayed(Duration(milliseconds: 1500));

    // If interpreter is not loaded
    if (_interpreter == null) {
      print('Interpreter is not initialized');
      Navigator.of(context).pop(); // Dismiss the loading dialog
      return;
    }

    // Read and preprocess the image
    var imageBytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) return;

    // Resize the image to 3844x1575
    var resizedImage = img.copyResize(image, width: 3844, height: 1575);
    setState(() {
      _resizedImageBytes = Uint8List.fromList(img.encodePng(resizedImage));
    });

    // ROI parameters for first region(Concealed Value)
    int x1 = 471;
    int y1 = 0;
    int width1 = 475;
    int height1 = 555;

    // ROI parameters for second region(OVD)
    int x2 = 465;
    int y2 = 633;
    int width2 = 516;
    int height2 = 559;

    // Crop the image based on ROIs
    var croppedImage1 = img.copyCrop(resizedImage, x1, y1, width1, height1);
    setState(() {
      _croppedImageBytes1 = Uint8List.fromList(img.encodePng(croppedImage1));
    });

    var croppedImage2 = img.copyCrop(resizedImage, x2, y2, width2, height2);
    setState(() {
      _croppedImageBytes2 = Uint8List.fromList(img.encodePng(croppedImage2));
    });

    // Resize cropped images to model input size
    croppedImage1 = img.copyResize(croppedImage1, width: 299, height: 299);
    croppedImage2 = img.copyResize(croppedImage2, width: 299, height: 299);

    // Convert img.Image to cv.Mat
    Uint8List bytes1 = Uint8List.fromList(img.encodeBmp(croppedImage1));
    Uint8List bytes2 = Uint8List.fromList(img.encodeBmp(croppedImage2));

    var cvImage1 = await cv.imdecode(bytes1, cv.IMREAD_COLOR);
    var cvImage2 = await cv.imdecode(bytes2, cv.IMREAD_COLOR);

    var img_gray1 = await cv.cvtColor(cvImage1, cv.COLOR_BGR2GRAY);
    var img_gray2 = await cv.cvtColor(cvImage2, cv.COLOR_BGR2GRAY);

    var edges1 = await cv.canny(img_gray1, 100, 200);
    var edges2 = await cv.canny(img_gray2, 100, 200);

    var img_bgr1 = await cv.cvtColor(edges1, cv.COLOR_GRAY2BGR);
    var img_bgr2 = await cv.cvtColor(edges2, cv.COLOR_GRAY2BGR);

    // Preprocess the images
    List<double> input1 = await preprocessImage(img_bgr1);
    List<double> input2 = await preprocessImage(img_bgr2);

    // After processing img_bgr1 and img_bgr2
    var (success1, processedBytes1) = await cv.imencode('.png', img_bgr1);
    var (success2, processedBytes2) = await cv.imencode('.png', img_bgr2);

    if (success1 && success2) {
      setState(() {
        _processedImageBytes1 = processedBytes1;
        _processedImageBytes2 = processedBytes2;
      });
    } else {
      print('Failed to encode one or both images');
    }

    // Combine inputs if necessary
    var inputTensor1 = Float32List.fromList(input1).reshape([1, 299, 299, 3]);
    var output1 = List.filled(1, 0.0).reshape([1, 1]);

    var inputTensor2 = Float32List.fromList(input2).reshape([1, 299, 299, 3]);
    var output2 = List.filled(1, 0.0).reshape([1, 1]);

    try {
      Navigator.of(context).pop(); // Dismiss the loading dialog

      _interpreter!.run(inputTensor1, output1);
      _interpreter!.run(inputTensor2, output2);
      double concealedValueScore = output1[0][0];
      double ovdScore = output2[0][0];

      // Create an instance of BanknoteAuthenticator
      final authenticator = BanknoteAuthenticator();

      // Combine scores and get prediction
      double combinedScore =
          authenticator.combineScores(ovdScore, concealedValueScore);
      String prediction = authenticator.getPrediction(combinedScore);
      bool isReal = prediction == 'Real';

      print(
          'OVD Score: $ovdScore, Concealed Value Score: $concealedValueScore');
      print('Combined Score: ${combinedScore.toStringAsFixed(2)}');
      print('Prediction: $prediction');

      final player = AudioPlayer();
      if (prediction == 'Real') {
        await player.play(AssetSource('audio/real_audio.mp3'));
      } else {
        await player.play(AssetSource('audio/fake_audio.mp3'));
      }

      DateFormat dateFormat = DateFormat("yyyyMMddHHmmss");
      String datetime = dateFormat.format(DateTime.now());
      await ApplicationController.instance.incrementTransNumber();
      if (_resizedImageBytes != null) {
        Directory docuDir = await getApplicationDocumentsDirectory();
        File trnImage =
            await File(path.join(docuDir.path, "${datetime + ".jpg"}"))
                .create();
        await trnImage.writeAsBytes(_resizedImageBytes!);
        ApplicationController.instance.createTransaction(
            [ApplicationController.instance.numTrans.value, datetime, isReal]);
      }

      showTransDialog(
          context: context,
          isGenuine: isReal,
          transNum: ApplicationController.instance.numTrans.value,
          image: Image.memory(_resizedImageBytes!),
          date: datetime);
      //     .then((_) {
      //   // This code will run after the TransDialog is closed
      //   _showPredictionResult(
      //       prediction, combinedScore, ovdScore, concealedValueScore);
      // });
    } catch (e) {
      print('Error running inference: $e');
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await processAndPredictImage(image.path, context);
    }
  }

  Future _pickCropAndPredictImage(BuildContext context) async {
    // Show a full-screen dialog with options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: pureWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Image Source",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    context: context,
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image =
                          await _picker.pickImage(source: ImageSource.camera);
                      if (image != null) {
                        _cropAndProcessImage(image.path, context);
                      }
                    },
                  ),
                  Expanded(
                    child: _buildQuickActionCard(
                      context: context,
                      icon: Icons.photo_library_rounded,
                      title: "Gallery",
                      subtitle: "Select from photos",
                      onTap: () async {
                        try {
                          // Get the status bar height to adjust UI positioning
                          final statusBarHeight =
                              MediaQuery.of(context).padding.top;

                          // Use ImagePicker directly
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            // Optional parameters to improve image quality
                            imageQuality: 100,
                            maxWidth: 4000,
                            maxHeight: 4000,
                          );

                          if (image != null) {
                            // Crop the image with adjusted UI settings
                            CroppedFile? croppedFile =
                                await ImageCropper().cropImage(
                              sourcePath: image.path,
                              compressQuality: 100,
                              compressFormat: ImageCompressFormat.jpg,
                              uiSettings: [
                                AndroidUiSettings(
                                  toolbarTitle: 'Crop Image',
                                  toolbarColor: primaryColor,
                                  toolbarWidgetColor: Colors.white,
                                  initAspectRatio:
                                      CropAspectRatioPreset.original,
                                  lockAspectRatio: false,
                                  activeControlsWidgetColor: primaryColor,
                                  statusBarColor: primaryColor,
                                  hideBottomControls: false,
                                  // Add extra padding to account for status bar
                                  dimmedLayerColor:
                                      Colors.black.withOpacity(0.6),
                                  // Adjust toolbar height to avoid status bar overlap
                                ),
                                IOSUiSettings(
                                  title: 'Crop Image',
                                  doneButtonTitle: 'Done',
                                  cancelButtonTitle: 'Cancel',
                                  hidesNavigationBar: false,
                                  aspectRatioPickerButtonHidden: false,
                                ),
                              ],
                            );

                            if (croppedFile != null) {
                              await processAndPredictImage(
                                  croppedFile.path, context);
                            }
                          }
                        } catch (exception) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Error selecting or processing image: $exception'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cropAndProcessImage(
      String imagePath, BuildContext context) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      compressQuality: 100,
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: primaryColor,
          statusBarColor: primaryColor,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          hidesNavigationBar: false,
          aspectRatioPickerButtonHidden: false,
        ),
      ],
    );

    if (croppedFile != null) {
      await processAndPredictImage(croppedFile.path, context);
    }
  }

  void _showPredictionResult(String prediction, double combinedScore,
      double ovdScore, double concealedScore) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Prediction Result',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 26, fontWeight: FontWeight.w600, color: primaryColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Combined Score: ${(combinedScore * 100).toStringAsFixed(2)}',
                ),
                Text(
                  'OVD Score: ${(ovdScore * 100).toStringAsFixed(2)}',
                ),
                Text(
                    'Concealed Score: ${(concealedScore * 100).toStringAsFixed(2)}%'),
                SizedBox(height: 10),
                _resizedImageBytes != null
                    ? Column(
                        children: [
                          Text('Resized Image:'),
                          Image.memory(_resizedImageBytes!),
                        ],
                      )
                    : Container(),
                SizedBox(height: 3),
                _croppedImageBytes1 != null
                    ? Column(
                        children: [
                          Text('Cropped Image 1:'),
                          Image.memory(_croppedImageBytes1!),
                        ],
                      )
                    : Container(),
                SizedBox(height: 3),
                _croppedImageBytes2 != null
                    ? Column(
                        children: [
                          Text('Cropped Image 2:'),
                          Image.memory(_croppedImageBytes2!),
                        ],
                      )
                    : Container(),
                SizedBox(height: 3),
                _processedImageBytes1 != null
                    ? Column(
                        children: [
                          Text('Processed Image 1:'),
                          Image.memory(_processedImageBytes1!),
                        ],
                      )
                    : Container(),
                SizedBox(height: 3),
                _processedImageBytes2 != null
                    ? Column(
                        children: [
                          Text('Processed Image 2:'),
                          Image.memory(_processedImageBytes2!),
                        ],
                      )
                    : Container(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        color: bgWhite,
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    width: size.width,
                    height: 230,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [bgTint, primaryColorDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.90],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(40),
                        bottomLeft: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -50,
                          child: Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          top: 50,
                          child: Opacity(
                            opacity: 0.3,
                            child: Image.asset(
                              kauthLogoFull,
                              height: 200,
                              width: 200,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Container(
                            height: 200,
                            width: size.width,
                            padding: EdgeInsets.fromLTRB(30, 0, 30, 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome to",
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: pureWhite.withOpacity(0.9),
                                  ),
                                ),
                                Text(
                                  "KAuth",
                                  style: GoogleFonts.poppins(
                                    fontSize: 50,
                                    fontWeight: FontWeight.w700,
                                    color: pureWhite,
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Banknote Authentication System",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: pureWhite.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 25, 20, 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Quick Actions",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                context: context,
                                icon: Icons.camera_alt_rounded,
                                title: "Scan Banknote",
                                subtitle: "Use camera to verify",
                                onTap: () async {
                                  try {
                                    List<String> pictures =
                                        await CunningDocumentScanner
                                                .getPictures(
                                                    noOfPages: 1,
                                                    isGalleryImportAllowed:
                                                        true) ??
                                            [];
                                    if (pictures.isNotEmpty) {
                                      await processAndPredictImage(
                                          pictures[0], context);
                                    }
                                  } catch (exception) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Error capturing or processing image: $exception'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: _buildQuickActionCard(
                                context: context,
                                icon: Icons.photo_library_rounded,
                                title: "Gallery",
                                subtitle: "Select from photos",
                                onTap: () async {
                                  try {
                                    // Get the status bar height to adjust UI positioning
                                    final statusBarHeight =
                                        MediaQuery.of(context).padding.top;

                                    // Use ImagePicker directly
                                    final XFile? image =
                                        await _picker.pickImage(
                                      source: ImageSource.gallery,
                                      // Optional parameters to improve image quality
                                      imageQuality: 100,
                                      maxWidth: 4000,
                                      maxHeight: 4000,
                                    );

                                    if (image != null) {
                                      // Crop the image with adjusted UI settings
                                      CroppedFile? croppedFile =
                                          await ImageCropper().cropImage(
                                        sourcePath: image.path,
                                        compressQuality: 100,
                                        compressFormat: ImageCompressFormat.jpg,
                                        uiSettings: [
                                          AndroidUiSettings(
                                            toolbarTitle: 'Crop Image',
                                            toolbarColor: primaryColor,
                                            toolbarWidgetColor: Colors.white,
                                            initAspectRatio:
                                                CropAspectRatioPreset.original,
                                            lockAspectRatio: false,
                                            activeControlsWidgetColor:
                                                primaryColor,
                                            statusBarColor: primaryColor,
                                            hideBottomControls: false,
                                            // Add extra padding to account for status bar
                                            dimmedLayerColor:
                                                Colors.black.withOpacity(0.6),
                                            // Adjust toolbar height to avoid status bar overlap
                                          ),
                                          IOSUiSettings(
                                            title: 'Crop Image',
                                            doneButtonTitle: 'Done',
                                            cancelButtonTitle: 'Cancel',
                                            hidesNavigationBar: false,
                                            aspectRatioPickerButtonHidden:
                                                false,
                                          ),
                                        ],
                                      );

                                      if (croppedFile != null) {
                                        await processAndPredictImage(
                                            croppedFile.path, context);
                                      }
                                    }
                                  } catch (exception) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Error selecting or processing image: $exception'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Recent Transactions",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Get.to(
                                  () => TransactionScreen(),
                                  transition: Transition.fadeIn,
                                  duration: Duration(milliseconds: 200),
                                );
                              },
                              icon: Icon(Icons.history, size: 18),
                              label: Text(
                                "View All",
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: pureWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(15),
                          child: Obx(
                            () => ApplicationController
                                        .instance.prevTrans.length >
                                    0
                                ? Column(
                                    children: [
                                      for (int i = 0;
                                          i <
                                              (ApplicationController.instance
                                                          .prevTrans.length >=
                                                      3
                                                  ? 3
                                                  : ApplicationController
                                                      .instance
                                                      .prevTrans
                                                      .length);
                                          i++)
                                        Container(
                                          margin: EdgeInsets.only(
                                              bottom: i < 2 ? 10 : 0),
                                          child: TransactionCard(
                                            index: i,
                                            transNum: int.parse(
                                                ApplicationController
                                                    .instance
                                                    .prevTrans[
                                                        ApplicationController
                                                                .instance
                                                                .prevTrans
                                                                .length -
                                                            1 -
                                                            i][0]
                                                    .toString()),
                                            date: ApplicationController
                                                .instance
                                                .prevTrans[ApplicationController
                                                        .instance
                                                        .prevTrans
                                                        .length -
                                                    1 -
                                                    i][1]
                                                .toString(),
                                            isReal: ApplicationController
                                                        .instance
                                                        .prevTrans[
                                                            ApplicationController
                                                                    .instance
                                                                    .prevTrans
                                                                    .length -
                                                                1 -
                                                                i][2]
                                                        .toString()
                                                        .toLowerCase() ==
                                                    "true"
                                                ? true
                                                : false,
                                          ),
                                        ),
                                    ],
                                  )
                                : Container(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.history_rounded,
                                          size: 50,
                                          color: disabledGrey.withOpacity(0.5),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          "No transactions yet",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: disabledGrey,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          "Scan a banknote to get started",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color:
                                                disabledGrey.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 25),
                        Container(
                          height: 185,
                          width: MediaQuery.of(context).size.width - 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, primaryColorDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: -8,
                                right: -8,
                                child: SizedBox(
                                  height: 138,
                                  child: Image.asset(
                                    knowmore,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(20, 18, 20, 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Learn More",
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: pureWhite,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.6,
                                      child: Text(
                                        "Discover more about Philippine banknotes and security features",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: pureWhite.withOpacity(0.9),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        Get.to(
                                          () => LearnmoreScreen(),
                                          transition: Transition.fadeIn,
                                          duration: Duration(milliseconds: 200),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: pureWhite,
                                        foregroundColor: primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 8),
                                        minimumSize: Size(0, 36),
                                      ),
                                      child: Text(
                                        "Explore",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 80), // Space for bottom navigation
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                height: 70,
                decoration: BoxDecoration(
                  color: pureWhite,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: Icons.home_rounded,
                      label: "Home",
                      isActive: true,
                      onTap: () {},
                    ),
                    _buildNavItem(
                      icon: Icons.history_rounded,
                      label: "History",
                      isActive: false,
                      onTap: () {
                        Get.to(
                          () => TransactionScreen(),
                          transition: Transition.fadeIn,
                          duration: Duration(milliseconds: 200),
                        );
                      },
                    ),
                    SizedBox(width: 60), // Space for center button
                    _buildNavItem(
                      icon: Icons.info_outline_rounded,
                      label: "Learn",
                      isActive: false,
                      onTap: () {
                        Get.to(
                          () => LearnmoreScreen(),
                          transition: Transition.fadeIn,
                          duration: Duration(milliseconds: 200),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.help_outline_rounded,
                      label: "Help",
                      isActive: false,
                      onTap: () {
                        Get.to(
                          () => OnboardingScreen(),
                          transition: Transition.fadeIn,
                          duration: Duration(milliseconds: 200),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 35,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () async {
                      try {
                        List<String> pictures =
                            await CunningDocumentScanner.getPictures(
                                    noOfPages: 1,
                                    isGalleryImportAllowed: true) ??
                                [];
                        if (pictures.isNotEmpty) {
                          await processAndPredictImage(pictures[0], context);
                        }
                      } catch (exception) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Error capturing or processing image: $exception'),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      color: pureWhite,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}

class TransactionCard extends StatefulWidget {
  final int index;
  final int transNum;
  final String date;
  final bool isReal;
  const TransactionCard({
    super.key,
    required this.index,
    required this.transNum,
    required this.date,
    required this.isReal,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Format the date for display
    String formattedDate =
        "${widget.date.substring(0, 4)}-${widget.date.substring(4, 6)}-${widget.date.substring(6, 8)} ${widget.date.substring(8, 10)}:${widget.date.substring(10, 12)}:${widget.date.substring(12, 14)}";

    return Container(
      decoration: BoxDecoration(
        color: widget.isReal
            ? genuineGreen.withOpacity(0.05)
            : fakeRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: widget.isReal
              ? genuineGreen.withOpacity(0.3)
              : fakeRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onHover: (hover) {
            setState(() {
              isHovered = hover;
            });
          },
          onTap: () async {
            Directory docuDir = await getApplicationDocumentsDirectory();
            String originalImagePath =
                path.join(docuDir.path, "${widget.date}.jpg");

            // Compress the image before displaying it
            File compressedImage = await compressImage(File(originalImagePath));

            // Display the compressed image in the dialog
            showTransDialog(
              context: context,
              isGenuine: widget.isReal,
              transNum: widget.transNum,
              image: Image.file(compressedImage), // Using compressed image
              date: formattedDate,
            );
          },
          borderRadius: BorderRadius.circular(15),
          splashColor: widget.isReal
              ? genuineGreen.withOpacity(0.1)
              : fakeRed.withOpacity(0.1),
          highlightColor: widget.isReal
              ? genuineGreen.withOpacity(0.05)
              : fakeRed.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.isReal
                        ? genuineGreen.withOpacity(0.1)
                        : fakeRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isReal ? Icons.check_circle : Icons.cancel,
                    color: widget.isReal ? genuineGreen : fakeRed,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Transaction #${widget.transNum}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: disabledGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.isReal ? genuineGreen : fakeRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.isReal ? "Real" : "Fake",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: pureWhite,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade300,
                    size: 22,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            "Delete Transaction",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          content: Text(
                            "Are you sure you want to delete this transaction?",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: darkGrey,
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text(
                                "Cancel",
                                style: GoogleFonts.poppins(
                                  color: disabledGrey,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: pureWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "Delete",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                ApplicationController.instance
                                    .deleteTransaction(widget.transNum);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to compress the image
  Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(dir.path, '${widget.date}_compressed.jpg');

    // Perform the image compression
    XFile? compressedImage = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path, // Source image path
      targetPath, // Destination path
      quality: 40, // Set quality level (lower value compresses more)
    );

    // Convert XFile to File and return the compressed image if successful, otherwise return the original image
    return compressedImage != null ? File(compressedImage.path) : file;
  }
}

class SelectButton extends StatefulWidget {
  final VoidCallback onTap;
  final String buttonText;
  final IconData icon;
  const SelectButton(
      {super.key,
      required this.onTap,
      required this.buttonText,
      required this.icon});

  @override
  State<SelectButton> createState() => _SelectButtonState();
}

class _SelectButtonState extends State<SelectButton> {
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        borderRadius: BorderRadius.circular(40),
        color: bgWhite,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (details) {
            setState(() {
              isPressed = true;
            });
          },
          onTapUp: (details) {
            setState(() {
              isPressed = false;
            });
          },
          borderRadius: BorderRadius.circular(30),
          splashColor: primaryColor,
          highlightColor: primaryColor.withOpacity(0.1),
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: Container(
              height: double.infinity,
              width: double.infinity,
              alignment: Alignment.center,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: primaryColor, width: 4.0)),
              child: Column(
                children: [
                  Icon(
                    widget.icon,
                    color: isPressed ? pureWhite : primaryColor,
                    size: 50,
                  ),
                  Text(
                    widget.buttonText,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: isPressed ? pureWhite : disabledGrey,
                        height: 1.1,
                        fontSize: 16),
                  )
                ],
                mainAxisSize: MainAxisSize.min,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildQuickActionCard({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 30,
            ),
          ),
          SizedBox(height: 15),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 5),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: disabledGrey,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildNavItem({
  required IconData icon,
  required String label,
  required bool isActive,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? primaryColor : disabledGrey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? primaryColor : disabledGrey,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildImageSourceOption({
  required BuildContext context,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
          ),
        ],
      ),
    ),
  );
}
