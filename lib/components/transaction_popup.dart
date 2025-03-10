import 'package:cashguard/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

Future<dynamic> showTransDialog(
    {required BuildContext context,
    required bool isGenuine,
    required int transNum,
    required Image image,
    required String date,
    double? width}) {
  return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          alignment: Alignment.center,
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: bgWhite,
                        borderRadius: BorderRadius.circular(30.0),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          )
                        ]),
                    margin: EdgeInsets.only(right: 12, top: 40),
                    padding: EdgeInsets.all(20),
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 40),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isGenuine ? genuineGreen : fakeRed,
                              width: 3,
                            ),
                          ),
                          padding: EdgeInsets.all(5),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: image,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Authentication Result",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isGenuine
                                ? genuineGreen.withOpacity(0.1)
                                : fakeRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isGenuine ? genuineGreen : fakeRed,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "This banknote is",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: darkGrey,
                                ),
                              ),
                              Text(
                                isGenuine ? "GENUINE" : "COUNTERFEIT",
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isGenuine ? genuineGreen : fakeRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Divider(color: disabledGrey.withOpacity(0.3)),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Transaction #${transNum.toString()}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  date,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: disabledGrey,
                                  ),
                                ),
                              ],
                            ),
                            if (isGenuine)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: genuineGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: pureWhite, size: 16),
                                    SizedBox(width: 5),
                                    Text(
                                      "Verified",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: pureWhite,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: fakeRed,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: pureWhite, size: 16),
                                    SizedBox(width: 5),
                                    Text(
                                      "Alert",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: pureWhite,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: pureWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text(
                            "Close",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: isGenuine ? genuineGreen : fakeRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: pureWhite, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: (isGenuine ? genuineGreen : fakeRed)
                                  .withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          isGenuine ? Icons.check : Icons.close,
                          color: pureWhite,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOut);
      });
}
