import 'dart:typed_data';

import 'package:cashguard/constants.dart';
import 'package:cashguard/controllers/application_controller.dart';
import 'package:cashguard/screens/homescreen.dart';
import 'package:cashguard/screens/learnmorescreen.dart';
import 'package:cashguard/screens/onboardingscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({
    super.key,
  });
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
                    height: 180,
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
                          left: 0,
                          bottom: 0,
                          child: Container(
                            height: 120,
                            width: size.width,
                            padding: EdgeInsets.fromLTRB(30, 0, 30, 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Transaction",
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: pureWhite,
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      "History",
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: pureWhite,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                Obx(() => Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: pureWhite.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "${ApplicationController.instance.prevTrans.length} Transactions",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: pureWhite,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(() => Container(
                        padding: EdgeInsets.fromLTRB(20, 25, 20, 100),
                        child: ApplicationController.instance.prevTrans.length >
                                0
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "All Transactions",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 15),
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
                                    child: Column(
                                      children: [
                                        for (int i = 0;
                                            i <
                                                ApplicationController
                                                    .instance.prevTrans.length;
                                            i++)
                                          Container(
                                            margin: EdgeInsets.only(
                                                bottom: i <
                                                        ApplicationController
                                                                .instance
                                                                .prevTrans
                                                                .length -
                                                            1
                                                    ? 10
                                                    : 0),
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
                                                  .prevTrans[
                                                      ApplicationController
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
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                height: size.height - 280,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      size: 80,
                                      color: disabledGrey.withOpacity(0.5),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      "No transactions yet",
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: disabledGrey,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Scan a banknote to get started",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: disabledGrey.withOpacity(0.7),
                                      ),
                                    ),
                                    SizedBox(height: 30),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Get.back();
                                      },
                                      icon: Icon(Icons.camera_alt_rounded),
                                      label: Text("Scan Now"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: pureWhite,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      )),
                ],
              ),
            ),
            // Bottom Navigation Bar
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
                      isActive: false,
                      onTap: () {
                        Get.back(
                          closeOverlays: true,
                          canPop: true,
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.history_rounded,
                      label: "History",
                      isActive: true,
                      onTap: () {},
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
            // Center Scan Button
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
                          // Navigate back to home screen with a fade transition
                          Get.off(
                            () => Homescreen(),
                            transition: Transition.fade,
                            duration: Duration(milliseconds: 200),
                          );
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
}

// Add this helper function from the homescreen
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
