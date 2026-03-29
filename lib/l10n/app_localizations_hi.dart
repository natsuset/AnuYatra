// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Anuyatra';

  @override
  String get appNameStyled => 'Anuyātrā';

  @override
  String get appTagline => 'असली विवाह का अनुभव';

  @override
  String get appTitle => 'Anuyatra - The Real Matrimony App';

  @override
  String get enterPhoneTitle => 'अपना फ़ोन नंबर दर्ज करें';

  @override
  String get enterPhoneSubtitle => 'हम आपको एक वेरिफिकेशन कोड भेजेंगे';

  @override
  String get sendOtp => 'OTP भेजें';

  @override
  String get verifyNumber => 'अपना नंबर सत्यापित करें';

  @override
  String get verifyAndContinue => 'सत्यापित करें और जारी रखें';

  @override
  String get resendCode => 'कोड दोबारा भेजें';

  @override
  String get completeProfile => 'अपनी प्रोफ़ाइल पूरी करें';

  @override
  String get demoOtpHint =>
      'Demo mode: Any phone number works.\nUse OTP code: 123456';

  @override
  String get otpHint => 'Hint: The OTP is 123456';

  @override
  String get demoOtpAlways => 'Demo: OTP code is always 123456';

  @override
  String get invalidPhoneError => 'कृपया 10 अंकों का वैध फ़ोन नंबर दर्ज करें';

  @override
  String get invalidOtpError => 'कृपया पूरा 6-अंकीय कोड दर्ज करें';

  @override
  String get nameRequired => 'नाम आवश्यक है';

  @override
  String get agencyNameRequired => 'एजेंसी का नाम आवश्यक है';

  @override
  String get welcome => 'स्वागत है!';

  @override
  String registeringAs(String role) {
    return '$role के रूप में पंजीकरण';
  }

  @override
  String settingUpAs(String role) {
    return '$role के रूप में सेटअप';
  }

  @override
  String otpSentTo(String phone) {
    return '$phone पर भेजा गया 6-अंकीय कोड दर्ज करें';
  }

  @override
  String get howToUseAnuyatra => 'आप Anuyatra का उपयोग कैसे करना चाहते हैं?';

  @override
  String get home => 'होम';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get messages => 'संदेश';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get myProfile => 'मेरी प्रोफ़ाइल';

  @override
  String get search => 'खोजें';

  @override
  String get discover => 'खोजें';

  @override
  String get sharedProfiles => 'साझा प्रोफ़ाइल';

  @override
  String get linkRequests => 'लिंक अनुरोध';

  @override
  String get agencySettings => 'एजेंसी सेटिंग्स';

  @override
  String get agencyInformation => 'एजेंसी जानकारी';

  @override
  String get brokerRoster => 'दलाल सूची';

  @override
  String get quickActions => 'त्वरित क्रियाएं';

  @override
  String get account => 'खाता';

  @override
  String get appearance => 'रूप-रंग';

  @override
  String get session => 'सत्र';

  @override
  String get anuyatraHub => 'Anuyatra Hub';

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get submit => 'जमा करें';

  @override
  String get done => 'हो गया';

  @override
  String get back => 'वापस';

  @override
  String get next => 'आगे';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get accept => 'स्वीकार करें';

  @override
  String get decline => 'अस्वीकार करें';

  @override
  String get findBrokers => 'दलाल खोजें';

  @override
  String get inviteBroker => 'दलाल को आमंत्रित करें';

  @override
  String get sendInvite => 'आमंत्रण भेजें';

  @override
  String get connectWithAgency => 'एजेंसी से जुड़ें';

  @override
  String get connectWithBroker => 'दलाल से जुड़ें';

  @override
  String get viewProfile => 'प्रोफ़ाइल देखें';

  @override
  String get forwardToChild => 'बच्चे को अग्रेषित करें';

  @override
  String get interested => 'रुचि है';

  @override
  String get maybe => 'शायद';

  @override
  String get pass => 'छोड़ें';

  @override
  String get pending => 'लंबित';

  @override
  String get noProfilesShared => 'अभी तक कोई प्रोफ़ाइल साझा नहीं की गई';

  @override
  String get noProfilesSharedHint =>
      'आपके दलालों द्वारा साझा की गई प्रोफ़ाइल यहाँ दिखेंगी';

  @override
  String get noResultsFound => 'कोई परिणाम नहीं मिला';

  @override
  String get noMessagesYet => 'अभी तक कोई संदेश नहीं';

  @override
  String get noMessagesHint => 'बातचीत शुरू करने के लिए संदेश भेजें';

  @override
  String get noConversationsYet => 'अभी तक कोई बातचीत नहीं';

  @override
  String get noBrokersInAgency => 'आपकी एजेंसी में कोई दलाल नहीं';

  @override
  String get noClientsYet => 'अभी तक कोई क्लाइंट नहीं';

  @override
  String get noBrokersConnected => 'कोई दलाल जुड़ा नहीं';

  @override
  String get noReceivedRequests => 'कोई प्राप्त अनुरोध नहीं';

  @override
  String get noSentRequests => 'कोई भेजा गया अनुरोध नहीं';

  @override
  String get noSharedProfilesForCandidate =>
      'आपके माता-पिता द्वारा साझा की गई प्रोफ़ाइल यहाँ समीक्षा के लिए दिखेंगी';

  @override
  String get profileNotFound => 'प्रोफ़ाइल नहीं मिली';

  @override
  String get profileNotFoundTitle => 'प्रोफ़ाइल नहीं मिली';

  @override
  String get genericError => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get sendOtpFailed => 'OTP भेजने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get verificationFailed => 'सत्यापन विफल। कृपया पुनः प्रयास करें।';

  @override
  String get profileSetupFailed => 'प्रोफ़ाइल सेटअप विफल';

  @override
  String get userNotFoundByPhone => 'इस फ़ोन नंबर से कोई उपयोगकर्ता नहीं मिला';

  @override
  String get notRegisteredAsBroker =>
      'यह उपयोगकर्ता दलाल के रूप में पंजीकृत नहीं है';

  @override
  String get logoutConfirmTitle => 'लॉगआउट';

  @override
  String get logoutConfirmMessage => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';

  @override
  String get logoutConfirmBroker => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';

  @override
  String get acceptRequestConfirm => 'यह अनुरोध स्वीकार करें?';

  @override
  String get declineRequestConfirm => 'यह अनुरोध अस्वीकार करें?';

  @override
  String get vivahaSamskara => 'विवाह संस्कार';

  @override
  String get vivahaSamskaraDesc => 'प्रीमियम विवाह तैयारी सेवाएं';

  @override
  String get trustVerification => 'विश्वास सत्यापन';

  @override
  String get financialCompatibility => 'वित्तीय अनुकूलता';

  @override
  String get comingSoon => 'और भी सुविधाएं जल्द आ रही हैं!';

  @override
  String get comingSoonHint => 'वर्चुअल मीटिंग, AI मिलान, और बहुत कुछ';

  @override
  String get comingSoonShort => 'जल्द आ रहा है!';

  @override
  String get activeBrokers => 'दलाल';

  @override
  String get activeClients => 'क्लाइंट';

  @override
  String get profilesManaged => 'प्रोफ़ाइल';

  @override
  String get profilesSharedStat => 'साझा';

  @override
  String get pendingRequestsStat => 'लंबित';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get darkThemeActive => 'डार्क थीम सक्रिय';

  @override
  String get lightThemeActive => 'लाइट थीम सक्रिय';

  @override
  String get routeNotFound => 'रूट नहीं मिला';

  @override
  String get pageNotFound => 'पेज नहीं मिला';

  @override
  String get goHome => 'होम पर जाएं';

  @override
  String get pleaseLogIn => 'कृपया लॉग इन करें';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get roleLabel => 'भूमिका';

  @override
  String get signOutSubtitle => 'अपने खाते से साइन आउट करें';

  @override
  String get noNameSet => 'कोई नाम नहीं';

  @override
  String get authErrorInvalidPhone =>
      'कृपया 10 अंकों का वैध भारतीय मोबाइल नंबर दर्ज करें।';

  @override
  String get authErrorSendOtpFailed =>
      'OTP भेजने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String authErrorInvalidOtpWithHint(String hint) {
    return 'अमान्य OTP। डेमो के लिए \"$hint\" उपयोग करें।';
  }

  @override
  String get authErrorInvalidOtp => 'अमान्य OTP। कृपया पुनः प्रयास करें।';

  @override
  String get authErrorVerificationFailed =>
      'सत्यापन विफल। कृपया पुनः प्रयास करें।';

  @override
  String authErrorProfileSetupFailed(String detail) {
    return 'प्रोफ़ाइल सेटअप विफल: $detail';
  }

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get noRecentActivity => 'कोई हाल की गतिविधि नहीं';

  @override
  String get recentActivityHint =>
      'साझा प्रोफ़ाइल और कनेक्शन की गतिविधि यहाँ दिखेगी';

  @override
  String get profileSharedActivity => 'प्रोफ़ाइल साझा की';

  @override
  String get connectionRequestActivity => 'कनेक्शन अनुरोध';

  @override
  String get welcomeBack => 'वापस आपका स्वागत है,';

  @override
  String get newBroker => 'नया दलाल';

  @override
  String get gettingStarted => 'शुरुआत हो रही है';

  @override
  String get yrsExperience => 'वर्ष का अनुभव';

  @override
  String get createProfileAction => 'प्रोफ़ाइल बनाएं';

  @override
  String get shareProfileAction => 'प्रोफ़ाइल साझा करें';

  @override
  String get viewRequestsAction => 'अनुरोध देखें';

  @override
  String get connectedClients => 'जुड़े हुए क्लाइंट';

  @override
  String get noConnectedClients => 'अभी तक कोई जुड़ा हुआ क्लाइंट नहीं।';

  @override
  String get brokerClientsHint =>
      'जब माता-पिता आपसे जुड़ेंगे, वे यहाँ दिखेंगे।';

  @override
  String acceptedRequestFrom(String name) {
    return '$name से अनुरोध स्वीकार किया';
  }

  @override
  String failedToAccept(String error) {
    return 'स्वीकार करने में विफल: $error';
  }

  @override
  String declinedRequestFrom(String name) {
    return '$name से अनुरोध अस्वीकार किया';
  }

  @override
  String failedToDecline(String error) {
    return 'अस्वीकार करने में विफल: $error';
  }

  @override
  String get lookingFor => 'की तलाश में';

  @override
  String get lookingForSection => 'की तलाश में';

  @override
  String get listedWith => 'सूचीबद्ध';

  @override
  String get brokersLabel => 'दलाल';

  @override
  String get brokerConversationsHint =>
      'जब माता-पिता आपसे जुड़ेंगे, बातचीत यहाँ दिखेगी।';

  @override
  String get managedProfiles => 'प्रबंधित प्रोफ़ाइल';

  @override
  String get noProfilesYetLabel => 'अभी कोई प्रोफ़ाइल नहीं';

  @override
  String get noProfilesYetHint =>
      'अभी तक कोई प्रोफ़ाइल नहीं। अपनी पहली प्रोफ़ाइल बनाएं।';

  @override
  String get shareProfileWith => 'प्रोफ़ाइल साझा करें';

  @override
  String get noConnectedParents =>
      'साझा करने के लिए कोई जुड़े हुए माता-पिता नहीं';

  @override
  String get agencyLabel => 'एजेंसी';

  @override
  String get experienceLabel => 'अनुभव';

  @override
  String get areasServedLabel => 'सेवित क्षेत्र';

  @override
  String get specializationsLabel => 'विशेषज्ञताएं';

  @override
  String get yearsLabel => 'वर्ष';

  @override
  String get linkedToParent => 'माता-पिता से जुड़ा';

  @override
  String get notLinked => 'जुड़ा नहीं';

  @override
  String get notLinkedHint => 'आप अभी तक किसी माता-पिता से नहीं जुड़े हैं।';

  @override
  String get linkAction => 'जोड़ें';

  @override
  String get profilesSharedWithYou => 'आपके साथ साझा प्रोफ़ाइल';

  @override
  String get profileAvailable => 'प्रोफ़ाइल उपलब्ध';

  @override
  String get profilesAvailable => 'प्रोफ़ाइल उपलब्ध';

  @override
  String get viewSharedProfiles => 'साझा प्रोफ़ाइल देखें';

  @override
  String get seeProfilesForwardedByParent =>
      'अपने माता-पिता द्वारा अग्रेषित प्रोफ़ाइल देखें';

  @override
  String get viewConnectionRequests => 'अपने कनेक्शन अनुरोध देखें';

  @override
  String get markedAsInterested => 'रुचि के रूप में चिह्नित';

  @override
  String get markedAsPass => 'छोड़ें के रूप में चिह्नित';

  @override
  String get linkToParentTitle => 'माता-पिता से जोड़ें';

  @override
  String linkRequestSentTo(String name) {
    return '$name को लिंक अनुरोध भेजा गया';
  }

  @override
  String get linkRequestMessage =>
      'मैं अपना खाता आपके खाते से जोड़ना चाहता/चाहती हूं।';

  @override
  String get received => 'प्राप्त';

  @override
  String get sent => 'भेजा गया';

  @override
  String get requestAccepted => 'अनुरोध स्वीकार किया गया';

  @override
  String get requestDeclined => 'अनुरोध अस्वीकार किया गया';

  @override
  String get connectedWith => 'से जुड़े';

  @override
  String get call => 'कॉल';

  @override
  String get chat => 'चैट';

  @override
  String get calling => 'कॉल हो रही है';

  @override
  String get cityLabel => 'शहर';

  @override
  String get stateLabel => 'राज्य';

  @override
  String get connectedBrokers => 'जुड़े हुए दलाल';

  @override
  String get linkedChild => 'जुड़ा हुआ बच्चा';

  @override
  String get viewLinkRequests => 'लिंक अनुरोध देखें';

  @override
  String get agencyBrokersTitle => 'एजेंसी दलाल';

  @override
  String notRegisteredBrokerFull(String name) {
    return '$name दलाल के रूप में पंजीकृत नहीं है';
  }

  @override
  String inviteSentTo(String phone) {
    return '$phone को आमंत्रण भेजा गया';
  }

  @override
  String get agencyClientsTitle => 'एजेंसी क्लाइंट';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get addNewBroker => 'अपनी एजेंसी में एक नया दलाल जोड़ें';

  @override
  String get agencySettingsSaved => 'एजेंसी सेटिंग्स सहेजी गईं!';

  @override
  String get clearSearch => 'खोज साफ करें';

  @override
  String get yrsExp => 'वर्ष का अनुभव';

  @override
  String get connectionRequestSent => 'कनेक्शन अनुरोध भेजा गया!';

  @override
  String profileCreated(String name) {
    return '$name बनाई गई!';
  }

  @override
  String get bride => 'दुल्हन';

  @override
  String get groom => 'दूल्हा';

  @override
  String get yourName => 'आपका नाम';

  @override
  String get enterYourFullName => 'अपना पूरा नाम दर्ज करें';

  @override
  String get agencyNameLabel => 'एजेंसी का नाम';

  @override
  String get aboutYou => 'आपके बारे में';

  @override
  String get aboutYouHint =>
      'परिवारों को अपने मैचमेकिंग अनुभव के बारे में बताएं...';

  @override
  String get yearsOfExperience => 'अनुभव के वर्ष';

  @override
  String get lookingForA => 'की तलाश में';

  @override
  String get iAmA => 'मैं हूं';

  @override
  String get yourAge => 'आपकी उम्र';

  @override
  String get stepBasicInfo => 'बुनियादी जानकारी';

  @override
  String get stepAgencyDetails => 'एजेंसी विवरण';

  @override
  String get stepContact => 'संपर्क';

  @override
  String get stepExperience => 'अनुभव';

  @override
  String get stepBusinessDetails => 'व्यावसायिक विवरण';

  @override
  String get stepChildDetails => 'बच्चे का विवरण';

  @override
  String get stepFamilyDetails => 'परिवार का विवरण';

  @override
  String get stepPersonal => 'व्यक्तिगत';

  @override
  String get agencyDetailsSection => 'एजेंसी विवरण';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get descriptionHint => 'अपनी एजेंसी और सेवाओं का वर्णन करें...';

  @override
  String get specializationsCommaSeparated => 'विशेषज्ञताएं (अल्पविराम से अलग)';

  @override
  String get contactInformationSection => 'संपर्क जानकारी';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get officePhoneLabel => 'ऑफिस फोन';

  @override
  String get websiteOptional => 'वेबसाइट (वैकल्पिक)';

  @override
  String get addMoreDetailsLater =>
      'आप एजेंसी सेटिंग्स से बाद में अधिक विवरण जोड़ सकते हैं';

  @override
  String get experienceExpertiseSection => 'अनुभव और विशेषज्ञता';

  @override
  String get areasServedCommaSeparated => 'सेवित क्षेत्र (अल्पविराम से अलग)';

  @override
  String get languagesSpokenCommaSeparated =>
      'बोली जाने वाली भाषाएं (अल्पविराम से अलग)';

  @override
  String get businessDetailsSection => 'व्यावसायिक विवरण';

  @override
  String get officeAddressOptional => 'ऑफिस का पता (वैकल्पिक)';

  @override
  String get feeStructureOptional => 'शुल्क संरचना (वैकल्पिक)';

  @override
  String get workingHoursOptional => 'काम के घंटे (वैकल्पिक)';

  @override
  String get childDetailsSection => 'आपके बच्चे का विवरण';

  @override
  String get childDetailsHint =>
      'यह जानकारी दलालों को उपयुक्त मिलान खोजने में मदद करती है';

  @override
  String get childNameLabel => 'बच्चे का नाम';

  @override
  String get fullNameHint => 'पूरा नाम';

  @override
  String get heightLabel => 'ऊंचाई';

  @override
  String get dietLabel => 'आहार';

  @override
  String get dietVegetarian => 'शाकाहारी';

  @override
  String get dietNonVeg => 'मांसाहारी';

  @override
  String get dietEggetarian => 'एग्गेटेरियन';

  @override
  String get dietVegan => 'वीगन';

  @override
  String get dietJain => 'जैन';

  @override
  String get educationLabel => 'शिक्षा';

  @override
  String get professionLabel => 'पेशा';

  @override
  String get emailOptionalLabel => 'आपका ईमेल (वैकल्पिक)';

  @override
  String get familyInformationSection => 'पारिवारिक जानकारी';

  @override
  String get familyTypeLabel => 'परिवार का प्रकार';

  @override
  String get jointFamilyLabel => 'संयुक्त परिवार';

  @override
  String get nuclearFamilyLabel => 'एकल परिवार';

  @override
  String get fatherOccupationLabel => 'पिता का व्यवसाय';

  @override
  String get motherOccupationLabel => 'माता का व्यवसाय';

  @override
  String get aboutFamilyLabel => 'परिवार के बारे में';

  @override
  String get aboutFamilyHint =>
      'अपनी पारिवारिक पृष्ठभूमि का संक्षेप में वर्णन करें...';

  @override
  String get shareWithChildDesc =>
      'इस प्रोफ़ाइल को अपने बच्चे की राय के लिए साझा करें';

  @override
  String get noChildLinkedMsg =>
      'अभी तक कोई बच्चा खाता आपकी प्रोफ़ाइल से जुड़ा नहीं है।';

  @override
  String get askChildToLink =>
      'अपने बच्चे से कहें कि वे एक खाता बनाएं और इसे आपसे जोड़ें।';

  @override
  String get linkedChildLabel => 'जुड़ा हुआ बच्चा';

  @override
  String get noChildLinkedLabel => 'कोई बच्चा जुड़ा नहीं';

  @override
  String profileForwardedTo(String name) {
    return 'प्रोफ़ाइल $name को अग्रेषित की गई';
  }

  @override
  String get forwardProfileButton => 'प्रोफ़ाइल अग्रेषित करें';

  @override
  String get viewBrokerProfile => 'दलाल की प्रोफ़ाइल देखें';

  @override
  String get muteNotifications => 'सूचनाएं म्यूट करें';

  @override
  String get clearChat => 'चैट साफ करें';

  @override
  String get callBroker => 'दलाल को कॉल करें';

  @override
  String get startRecording => 'रिकॉर्डिंग शुरू करें';

  @override
  String get voiceNoteComingSoon => 'वॉयस नोट सुविधा जल्द आ रही है!';

  @override
  String get reportProfile => 'प्रोफ़ाइल रिपोर्ट करें';

  @override
  String get contactBroker => 'दलाल से संपर्क करें';

  @override
  String get shareFeatureComingSoon => 'साझा करने की सुविधा जल्द आ रही है!';

  @override
  String get saveFeatureComingSoon => 'सहेजने की सुविधा जल्द आ रही है!';

  @override
  String get saveToDevice => 'डिवाइस पर सहेजें';

  @override
  String get profileShareMessage =>
      'यह एक प्रोफ़ाइल है जो मुझे लगता है आपके लिए परफेक्ट होगी। नीचे विवरण देखें।';

  @override
  String get yourShortlist => 'आपकी शॉर्टलिस्ट';

  @override
  String get sortBy => 'क्रमबद्ध करें';

  @override
  String get filter => 'फ़िल्टर';

  @override
  String get exportList => 'सूची निर्यात करें';

  @override
  String get noProfilesInShortlist => 'शॉर्टलिस्ट में कोई प्रोफ़ाइल नहीं';

  @override
  String get shortlistHint =>
      'जिन प्रोफ़ाइल को आप सहेजते हैं या रुचि दिखाते हैं वे यहाँ दिखेंगी';

  @override
  String get browseProfiles => 'प्रोफ़ाइल ब्राउज़ करें';

  @override
  String get trustAndVerification => 'विश्वास और सत्यापन';

  @override
  String get inviteVerifiers => 'सत्यापनकर्ताओं को आमंत्रित करें';

  @override
  String get sendInvites => 'आमंत्रण भेजें';

  @override
  String get completeVerification => 'सत्यापन पूरा करें';

  @override
  String get uploadDocuments => 'दस्तावेज़ अपलोड करें';

  @override
  String get trustReport => 'विश्वास रिपोर्ट';

  @override
  String get download => 'डाउनलोड';

  @override
  String get startingFinancialDiscussion => 'वित्तीय चर्चा शुरू हो रही है...';

  @override
  String get weddingBudgetPlanner => 'विवाह बजट प्लानर';

  @override
  String get startPlanning => 'योजना शुरू करें';

  @override
  String get completeProfileAction => 'प्रोफ़ाइल पूरी करें';

  @override
  String get completeNow => 'अभी पूरा करें';

  @override
  String get financialCounseling => 'वित्तीय परामर्श';

  @override
  String get bookSession => 'सत्र बुक करें';

  @override
  String get start => 'शुरू करें';

  @override
  String get later => 'बाद में';

  @override
  String get bookingInitiated => 'बुकिंग शुरू हो गई!';

  @override
  String get joiningMeeting => 'मीटिंग में शामिल हो रहे हैं...';

  @override
  String get rescheduleMeeting => 'मीटिंग पुनर्निर्धारित करें';

  @override
  String get rescheduleMeetingDesc =>
      'अपनी वर्चुअल पारिवारिक मीटिंग के लिए नया समय चुनें।';

  @override
  String get reschedule => 'पुनर्निर्धारित करें';

  @override
  String get schedule => 'शेड्यूल';

  @override
  String get openingMeetingScheduler => 'मीटिंग शेड्यूलर खोला जा रहा है...';

  @override
  String get helpComingSoon => 'सहायता और समर्थन जल्द आ रहा है';

  @override
  String get helpLabel => 'सहायता';

  @override
  String get designSystemDemo => 'Design System Demo';

  @override
  String get language => 'भाषा';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get telugu => 'తెలుగు';

  @override
  String get notSet => 'अज्ञात';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get offline => 'ऑफलाइन';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get none => 'कोई नहीं';

  @override
  String get linked => 'जुड़ा हुआ';

  @override
  String get markedAsMaybe => 'शायद के रूप में चिह्नित';

  @override
  String get typeAMessage => 'संदेश टाइप करें';

  @override
  String get community => 'समुदाय';

  @override
  String get caste => 'जाति';

  @override
  String get gotra => 'गोत्र';

  @override
  String get manglikStatus => 'मांगलिक स्थिति';

  @override
  String get annualIncome => 'वार्षिक आय';

  @override
  String get complexion => 'रंग';

  @override
  String get smoking => 'धूम्रपान';

  @override
  String get drinking => 'शराब';

  @override
  String get ownHouse => 'खुद का घर';

  @override
  String get ownCar => 'खुद की कार';

  @override
  String get willingToRelocate => 'स्थानांतरण के लिए तैयार';

  @override
  String get rashi => 'राशि';

  @override
  String get nakshatra => 'नक्षत्र';

  @override
  String get birthPlace => 'जन्म स्थान';

  @override
  String get birthTime => 'जन्म समय';

  @override
  String get familyValues => 'पारिवारिक मूल्य';

  @override
  String get siblings => 'भाई-बहन';

  @override
  String get brothers => 'भाई';

  @override
  String get sisters => 'बहनें';

  @override
  String get childLabel => 'बच्चा';

  @override
  String get brokerSharesHint => 'आपके जुड़े दलाल यहाँ प्रोफ़ाइल साझा करेंगे';

  @override
  String lookingForValue(String value) {
    return '$value की तलाश';
  }

  @override
  String resultsCount(String count) {
    return '$count परिणाम';
  }

  @override
  String get personalInformationSection => 'व्यक्तिगत जानकारी';

  @override
  String get canCompleteLater =>
      'आप बाद में अपनी प्रोफ़ाइल से अधिक विवरण भर सकते हैं';

  @override
  String get candidateLinkHint => 'आप बाद में अपने माता-पिता से जुड़ सकते हैं';

  @override
  String get candidateInfoBox =>
      'खाता बनाने के बाद, होम स्क्रीन से अपने माता-पिता से जुड़ें।';
}
