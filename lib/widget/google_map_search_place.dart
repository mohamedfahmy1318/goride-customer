import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/place_picker_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class GoogleMapSearchPlacesApi extends StatefulWidget {
  const GoogleMapSearchPlacesApi({super.key});

  @override
  GoogleMapSearchPlacesApiState createState() =>
      GoogleMapSearchPlacesApiState();
}

class GoogleMapSearchPlacesApiState extends State<GoogleMapSearchPlacesApi> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  var uuid = const Uuid();
  String? _sessionToken;
  List<dynamic> _placeList = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sessionToken = uuid.v4();
    _controller.addListener(_onChanged);
    // Auto focus on search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  _onChanged() {
    // Debounce to avoid too many API calls
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_controller.text.isNotEmpty && _controller.text.length >= 2) {
        getSuggestion(_controller.text);
      } else {
        setState(() {
          _placeList = [];
        });
      }
    });
  }

  void getSuggestion(String input) async {
    if (input.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';

      // Build request URL with enhanced parameters
      StringBuffer requestUrl = StringBuffer();
      requestUrl.write('$baseURL?input=${Uri.encodeComponent(input)}');
      requestUrl.write('&key=${Constant.mapAPIKey}');
      requestUrl.write('&sessiontoken=$_sessionToken');

      // Add language for Arabic support
      requestUrl.write('&language=ar');

      // Add location bias if current location is available
      if (Constant.currentLocation != null) {
        requestUrl.write(
            '&location=${Constant.currentLocation!.latitude},${Constant.currentLocation!.longitude}');
        requestUrl.write(
            '&radius=100000'); // 100km radius bias for better city coverage
      }

      // Global search - no country restriction
      // Users can search worldwide for streets, cities, etc.

      // Remove type restriction to include all places (cities, localities, streets, etc.)
      // This allows searching for cities like "سمنود" (Samanoud)

      var response = await http.get(Uri.parse(requestUrl.toString()));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          setState(() {
            _placeList = data['predictions'] ?? [];
            _isLoading = false;
          });
        } else {
          log('Places API error: ${data['status']} - ${data['error_message']}');
          setState(() {
            _placeList = [];
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      log('Search error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<PlaceDetailsModel?> getLatLang(String placeId) async {
    PlaceDetailsModel? placeDetailsModel;
    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/details/json';
      String request = '$baseURL?placeid=$placeId&key=${Constant.mapAPIKey}';
      var response = await http.get(Uri.parse(request));
      // if (kDebugMode) {
      //   log(response.body);
      // }
      if (response.statusCode == 200) {
        placeDetailsModel =
            PlaceDetailsModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      log(e.toString());
    }
    return placeDetailsModel;
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeChange.getThem()
          ? AppColors.darkBackground
          : AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            themeChange.getThem() ? AppColors.darkBackground : Colors.white,
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          child: Icon(
            Icons.arrow_back,
            color: themeChange.getThem() ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Search places'.tr,
          style: TextStyle(
            color: themeChange.getThem() ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextFormField(
                validator: (value) =>
                    value != null && value.isNotEmpty ? null : 'Required',
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.start,
                textDirection: TextDirection.rtl, // Support RTL for Arabic
                style: GoogleFonts.poppins(
                    color: themeChange.getThem() ? Colors.white : Colors.black),
                decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: themeChange.getThem()
                        ? AppColors.darkTextField
                        : AppColors.textField,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    prefixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.darkModePrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.search,
                            color: AppColors.darkModePrimary),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(
                          color: themeChange.getThem()
                              ? AppColors.darkTextFieldBorder
                              : AppColors.textFieldBorder,
                          width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      borderSide: const BorderSide(
                          color: AppColors.darkModePrimary, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(
                          color: themeChange.getThem()
                              ? AppColors.darkTextFieldBorder
                              : AppColors.textFieldBorder,
                          width: 1),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(
                          color: themeChange.getThem()
                              ? AppColors.darkTextFieldBorder
                              : AppColors.textFieldBorder,
                          width: 1),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(
                          color: themeChange.getThem()
                              ? AppColors.darkTextFieldBorder
                              : AppColors.textFieldBorder,
                          width: 1),
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _placeList = [];
                              });
                            },
                          )
                        : null,
                    hintText: "Search your location here".tr,
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                    ))),
            const SizedBox(height: 10),
            // Show hint text when no results
            if (_controller.text.isNotEmpty &&
                _placeList.isEmpty &&
                !_isLoading)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text(
                      'No places found. Try a different search.'.tr,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: _placeList.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey[300],
                ),
                itemBuilder: (context, index) {
                  final place = _placeList[index];
                  final mainText =
                      place["structured_formatting"]?["main_text"] ?? "";
                  final secondaryText =
                      place["structured_formatting"]?["secondary_text"] ?? "";

                  return ListTile(
                    onTap: () async {
                      ShowToastDialog.showLoader("Please wait".tr);
                      await getLatLang(place["place_id"]).then((value) {
                        if (value != null) {
                          ShowToastDialog.closeLoader();
                          // Generate new session token for next search
                          _sessionToken = uuid.v4();
                          Get.back(result: value);
                        }
                      });
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.darkModePrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.darkModePrimary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      mainText.isNotEmpty
                          ? mainText
                          : place["description"] ?? "",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                            themeChange.getThem() ? Colors.white : Colors.black,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: secondaryText.isNotEmpty
                        ? Text(
                            secondaryText,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
