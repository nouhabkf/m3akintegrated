/// Chaînes localisées pour Ma3ak (ar/fr).
class AppStrings {
  AppStrings(this.locale);

  final String locale;
  bool get isAr => locale == 'ar';

  static AppStrings fr() => AppStrings('fr');
  static AppStrings ar() => AppStrings('ar');

  /// Utilise 'ar' si lang == 'ar', sinon 'fr'.
  static AppStrings fromPreferredLanguage(String? lang) {
    if (lang?.toLowerCase() == 'ar') return ar();
    return fr();
  }

  String get appTitle => isAr ? 'معاك' : 'Ma3ak';
  String get splashLoading => isAr ? 'جاري التحميل...' : 'Chargement...';
  String get login => isAr ? 'تسجيل الدخول' : 'Connexion';
  String get register => isAr ? 'التسجيل' : 'Inscription';
  String get email => isAr ? 'البريد الإلكتروني' : 'Email';
  String get password => isAr ? 'كلمة المرور' : 'Mot de passe';
  String get loginButton => isAr ? 'دخول' : 'Se connecter';
  String get registerButton => isAr ? 'إنشاء حساب' : 'Créer un compte';
  String get loginWithGoogle => isAr ? 'المتابعة مع Google' : 'Continuer avec Google';
  String get noAccount => isAr ? 'ليس لديك حساب؟' : 'Pas encore de compte ?';
  String get haveAccount => isAr ? 'لديك حساب؟' : 'Déjà un compte ?';
  String get nom => isAr ? 'الاسم' : 'Nom';
  String get contact => isAr ? 'الاتصال' : 'Contact';
  String get ville => isAr ? 'المدينة' : 'Ville';
  String get role => isAr ? 'الدور' : 'Rôle';
  String get bio => isAr ? 'السيرة الذاتية' : 'Biographie';
  String get preferredLanguage => isAr ? 'اللغة المفضلة' : 'Langue préférée';
  String get handicapTypes => isAr ? 'أنواع الإعاقة' : 'Types de handicap';
  String get beneficiary => isAr ? 'مستفيد' : 'Bénéficiaire';
  String get companion => isAr ? 'مرافق' : 'Accompagnant';
  String get home => isAr ? 'الرئيسية' : 'Accueil';
  String get profile => isAr ? 'الملف الشخصي' : 'Profil';
  String get myAccompagnants => isAr ? 'مرافقوني' : 'Mes accompagnants';
  String get myBeneficiaires => isAr ? 'مستفيدوني' : 'Mes bénéficiaires';
  String get addAccompagnant => isAr ? 'إضافة مرافق' : 'Ajouter un accompagnant';
  String get removeAccompagnant => isAr ? 'إزالة' : 'Retirer';
  String get logout => isAr ? 'تسجيل الخروج' : 'Déconnexion';
  String get save => isAr ? 'حفظ' : 'Enregistrer';
  String get cancel => isAr ? 'إلغاء' : 'Annuler';
  String get editProfile => isAr ? 'تعديل الملف' : 'Modifier le profil';
  String get changePhoto => isAr ? 'تغيير الصورة' : 'Changer la photo';
  String get errorGeneric => isAr ? 'حدث خطأ' : "Une erreur s'est produite";
  String get errorInvalidCredentials =>
      isAr ? 'البريد أو كلمة المرور غير صحيحة' : 'Email ou mot de passe incorrect';

  // Design maquettes
  String get tagline => isAr ? 'تنقل شامل للجميع' : 'Mobilité inclusive pour tous';
  String get emailOrPhone => isAr ? 'البريد أو الهاتف' : 'E-mail / Téléphone';
  String get hintEmailOrPhone =>
      isAr ? 'أدخل بريدك أو رقم هاتفك' : 'Entrez votre e-mail ou téléphone';
  String get hintPassword =>
      isAr ? 'أدخل كلمة المرور' : 'Entrez votre mot de passe';
  String get connexion => isAr ? 'دخول' : 'Connexion';
  String get forgotPassword =>
      isAr ? 'كلمة المرور منسية؟' : 'Mot de passe oublié ?';
  String get or => isAr ? 'أو' : 'OU';
  String get signInWithGoogle =>
      isAr ? 'المتابعة مع Google' : 'Se connecter avec Google';
  String get signUp => isAr ? 'التسجيل' : "S'inscrire";

  String get createAccount => isAr ? 'إنشاء حسابك' : 'Créez votre compte';
  String get registerPageTitle => isAr ? 'إنشاء حساب' : 'Créer un compte';
  String get registerSubtitle =>
      isAr
          ? 'انضم إلى مجتمع معاك من أجل تنقل شامل في تونس.'
          : 'Rejoignez la communauté Ma3ak pour une mobilité inclusive en Tunisie.';
  String get dataSecurityMessage =>
      isAr
          ? 'بياناتك محمية وتُستخدم فقط لتسهيل تنقلك.'
          : 'Vos données sont sécurisées et utilisées uniquement pour faciliter votre transport.';
  String get iAm => isAr ? 'أنا...' : 'Je suis...';
  String get roleHandicap => isAr ? 'إعاقة' : 'Handicap';
  String get registerAlready => isAr ? 'مسجل بالفعل؟' : 'Déjà inscrit ?';
  String get registerWelcome =>
      isAr
          ? 'مرحباً بكم في معاك. قدم معلوماتك لمساعدتنا في تخصيص تجربة الوصول في تونس.'
          : 'Bienvenue sur Ma3ak. Veuillez fournir vos informations pour nous aider à personnaliser votre expérience d\'accessibilité en Tunisie.';
  String get fullName => isAr ? 'الاسم الكامل' : 'Nom complet';
  String get fullNameHint => isAr ? 'مثال: سامي منصور' : 'ex. Sami Mansour';
  String get handicapTypeOptional =>
      isAr ? 'نوع الإعاقة (اختياري)' : 'Type de handicap (Optionnel)';
  String get selectOption => isAr ? 'اختر' : 'Sélectionnez une option';
  String get handicapHelper =>
      isAr
          ? 'يساعدنا في اقتراح مسارات ووظائف مناسبة.'
          : 'Cela nous aide à suggérer des itinéraires et des fonctionnalités adaptés.';
  String get emailOrPhoneRequired =>
      isAr ? 'البريد أو رقم الهاتف *' : 'Email ou Numéro de téléphone *';
  String get emailOrPhoneHint =>
      isAr ? 'البريد أو +216...' : 'email@exemple.com ou +216...';
  String get continueBtn => isAr ? 'متابعة' : 'Continuer';
  String get alreadyHaveAccount =>
      isAr ? 'لديك حساب؟' : 'Vous avez déjà un compte?';

  String get personalInfo => isAr ? 'المعلومات الشخصية' : 'INFORMATIONS PERSONNELLES';
  String get securitySupport =>
      isAr ? 'الأمان والدعم' : 'SÉCURITÉ ET SUPPORT';
  String get emergencyContacts =>
      isAr ? 'جهات الاتصال الطارئة' : 'Contacts d\'urgence';
  String get assistanceHistory =>
      isAr ? 'سجل المساعدة' : 'Historique d\'assistance';
  String get settings => isAr ? 'الإعدادات' : 'Paramètres';
  String get verifiedUser => isAr ? 'مستخدم موثق' : 'Utilisateur vérifié';
  String get memberSince => isAr ? 'عضو منذ' : 'Membre depuis';
  String get assistedTrips => isAr ? 'رحلات مساعدة' : 'TRAJETS ASSISTÉS';
  String get communityRating => isAr ? 'تقييم المجتمع' : 'NOTE COMMUNAUTÉ';
  String get myProfile => isAr ? 'ملفي' : 'Mon Profil';
  String get health => isAr ? 'الصحة' : 'Santé';
  String get transport => isAr ? 'النقل' : 'Transport';
  String get places => isAr ? 'أماكن' : 'Milieux';
  /// Libellé onglet bas : module lieux / accessibilité.
  String get navLieux => isAr ? 'الأماكن' : 'Lieux';
  /// Bouton navigation vers la liste « à proximité ».
  String get nearbyPlacesNav => isAr ? 'بالقرب مني' : 'À proximité';
  String get phoneNumber => isAr ? 'رقم الهاتف' : 'Numéro de Téléphone';

  // Home page
  String get hello => isAr ? 'مرحباً' : 'Bonjour';
  String get whereToGoToday =>
      isAr ? 'أين تود الذهاب اليوم؟' : 'Où aimeriez-vous aller aujourd\'hui ?';
  String get searchAccessiblePlaces =>
      isAr ? 'البحث عن أماكن متاحة' : 'Rechercher des lieux accessibles';
  String get mainServices => isAr ? 'الخدمات الرئيسية' : 'Services Principaux';
  String get mobilityTransport =>
      isAr ? 'التنقل والنقل' : 'Mobilité & Transport';
  String get findAssistant =>
      isAr ? 'البحث عن مساعد' : 'Trouver un assistant';
  String get accessibilityCard =>
      isAr ? 'بطاقة إمكانية الوصول' : 'Carte d\'accessibilité';
  String get learningCenter =>
      isAr ? 'مركز التعلم' : 'Centre d\'apprentissage';
  String get nearbyAndActive =>
      isAr ? 'بالقرب ونشط' : 'À proximité & Actif';
  String get seeAll => isAr ? 'عرض الكل' : 'Voir tout';
  String get exploreNearby =>
      isAr ? 'استكشف الجوار' : 'Explorer à proximité';
  String get available => isAr ? 'متاح' : 'DISPONIBLE';
  String get open => isAr ? 'مفتوح' : 'OUVERT';

  // Home COMPANION (Accompagnant)
  String get companionRole => isAr ? 'مرافق' : 'ACCOMPAGNANT';
  String get followedUsers => isAr ? 'المستخدمون المتابعون' : 'Utilisateurs suivis';
  String get atHome => isAr ? 'في المنزل' : 'À DOMICILE';
  String get calm => isAr ? 'هادئ' : 'CALME';
  String get atDistance => isAr ? 'على بعد' : 'À 500M';
  String get active => isAr ? 'نشط' : 'ACTIF';
  String get assistanceRequests =>
      isAr ? 'طلبات المساعدة' : 'Demandes d\'assistance';
  String get newLabel => isAr ? 'جديد' : 'NOUVEAU';
  String get urgentTransport =>
      isAr ? 'نقل عاجل' : 'TRANSPORT URGENT';
  String get accept => isAr ? 'قبول' : 'Accepter';
  String get ignore => isAr ? 'تجاهل' : 'Ignorer';
  String get mySchedule => isAr ? 'جدولي' : 'Mon planning';
  String get medicalAccompaniment =>
      isAr ? 'مرافقة طبية' : 'Accompagnement médical';
  String get groceryHelp => isAr ? 'مساعدة في التسوق' : 'Aide aux courses';
  String get resourcesAndGuide =>
      isAr ? 'الموارد والدليل' : 'Ressources & Guide';
  String get goodPracticesGuide =>
      isAr ? 'دليل الممارسات الجيدة' : 'Guide des bonnes pratiques';
  String get firstAid => isAr ? 'الإسعافات الأولية' : 'Premiers secours';

  // Thème
  String get theme => isAr ? 'المظهر' : 'Thème';
  String get themeLight => isAr ? 'فاتح' : 'Clair';
  String get themeDark => isAr ? 'داكن' : 'Sombre';
  String get themeSystem => isAr ? 'حسب الجهاز' : 'Système';

  // Santé — assistant & tableau de bord (intégration appmaak)
  String get healthAssistantTitle =>
      isAr ? 'مساعد الصحة الذكي' : 'Assistant santé IA';
  String get healthAssistantSubtitle => isAr
      ? 'دردشة وصوت بالفرنسية أو الإنجليزية'
      : 'Chat & voix — français ou anglais';
  String get healthOpenChat =>
      isAr ? 'فتح المساعد' : 'Ouvrir l’assistant';
  String get healthFabChat =>
      isAr ? 'مساعد صحي' : 'Chat IA santé';
  String get healthScoreTitle => isAr ? 'مؤشر الصحة' : 'Score santé';
  String get healthScoreHint => isAr
      ? 'مؤشر تعليمي فقط — ليس تشخيصاً طبياً'
      : 'Indicateur éducatif — pas un diagnostic médical';
  String get healthGlycemiaTitle => isAr ? 'تحليل السكر في الدم' : 'Analyse glycémie';
  String get healthGlycemiaValueLabel =>
      isAr ? 'القيمة (مغ/دل)' : 'Valeur (mg/dL)';
  String get healthGlycemiaFasting =>
      isAr ? 'قياس على الريق (صائم)' : 'À jeun (mesure)';
  String get healthGlycemiaAnalyze =>
      isAr ? 'تحليل ذكي' : 'Analyser';
  String get healthGlycemiaInvalid =>
      isAr ? 'أدخل رقماً صالحاً' : 'Entrez un nombre valide';
  String get healthMedsTitle =>
      isAr ? 'تذكيرات الأدوية' : 'Rappels médicaments';
  String get healthMedsEmpty => isAr
      ? 'لا توجد تذكيرات. أضف دواءً ووقته.'
      : 'Aucun rappel. Ajoutez un médicament et son heure.';
  String get healthMedsAdd => isAr ? 'إضافة دواء' : 'Ajouter un médicament';
  String get healthMedName => isAr ? 'اسم الدواء' : 'Nom du médicament';
  String get healthMedTime => isAr ? 'الوقت' : 'Heure';
  String get healthNextReminders =>
      isAr ? 'التذكيرات القادمة' : 'Prochains rappels';
  String get healthSosTitle => isAr ? 'مساعد طوارئ (SOS)' : 'Aide SOS intelligente';
  String get healthSosBody => isAr
      ? 'يفتح المساعد للإجابة الصوتية والنصية. في الخطر الحقيقي اتصل بالنجدة.'
      : 'Ouvre l’assistant vocal et texte. En danger réel, appelez les secours.';
  String get healthSosButton => isAr ? 'فتح مساعد SOS' : 'Ouvrir assistant SOS';
  String get healthDisclaimerShort => isAr
      ? 'المعلومات عامة — استشر طبيبك.'
      : 'Infos générales — consultez votre médecin.';
  String get healthChatTitle => isAr ? 'مساعد الصحة' : 'Assistant santé';
  String get healthChatHint => isAr
      ? 'اكتب أو استخدم الميكروفون…'
      : 'Écrivez ou utilisez le micro…';
  String get healthChatSend => isAr ? 'إرسال' : 'Envoyer';
  String get healthVoiceLang => isAr ? 'لغة الصوت' : 'Langue vocale';
  String get healthVoiceAuto => isAr ? 'قراءة تلقائية' : 'Lecture auto';
  String get healthMicListen => isAr ? 'استماع' : 'Écouter';
  String get healthMicStop => isAr ? 'إيقاف' : 'Stop';
  String get healthVoiceUnavailable =>
      isAr ? 'الصوت غير متاح على هذا المتصفح' : 'Voix indisponible sur ce navigateur';

  // Communauté & Lieux
  String get community => isAr ? 'المجتمع' : 'Communauté';
  /// Accueil → même écran que la carte accessibilité (onglets lieux, posts, aide).
  String get communityHubHomeCardSubtitle => isAr
      ? 'منشورات، طلبات المساعدة، أماكن مهيأة'
      : 'Publications, demandes d’aide et lieux accessibles.';
  String get communityPlaces => isAr ? 'الأماكن' : 'Lieux accessibles';
  String get submitNewPlace => isAr ? 'إضافة مكان جديد' : 'Soumettre un lieu';
  String get allCategories => isAr ? 'الكل' : 'Toutes';
  String get noPlacesFound => isAr ? 'لم يتم العثور على أماكن' : 'Aucun lieu trouvé';
  String get tryDifferentFilters =>
      isAr ? 'جرب فلاتر مختلفة' : 'Essayez des filtres différents';
  String get errorLoadingPlaces =>
      isAr ? 'خطأ في تحميل الأماكن' : 'Erreur lors du chargement des lieux';
  String get retry => isAr ? 'إعادة المحاولة' : 'Réessayer';
  String get approved => isAr ? 'موافق عليه' : 'Approuvé';
  String get description => isAr ? 'الوصف' : 'Description';
  String get openingHours => isAr ? 'ساعات العمل' : 'Horaires';
  String get amenities => isAr ? 'المرافق' : 'Équipements';
  String get submittedBy => isAr ? 'تم الإرسال بواسطة' : 'Soumis par';
  String get errorLoadingPlace =>
      isAr ? 'خطأ في تحميل المكان' : 'Erreur lors du chargement du lieu';
  String get getDirections =>
      isAr ? 'الاتجاهات' : 'Itinéraire';
  String get reportIssue =>
      isAr ? 'الإبلاغ عن مشكلة' : 'Signaler un problème';
  String get sharePlace =>
      isAr ? 'مشاركة المكان' : 'Partager ce lieu';
  String get accessibilityScoreShort =>
      isAr ? 'الوصول' : 'Accès';
  String get noDescriptionForPlace =>
      isAr ? 'لا يوجد وصف لهذا المكان.' : 'Aucune description disponible pour ce lieu.';
  String get couldNotOpenMaps =>
      isAr ? 'تعذر فتح الخرائط' : 'Impossible d’ouvrir l’application cartes.';
  String get coordinatesUnavailable =>
      isAr ? 'إحداثيات غير متاحة لهذا المكان' : 'Coordonnées indisponibles pour ce lieu.';
  String get linkCopied =>
      isAr ? 'تم النسخ' : 'Copié dans le presse-papiers';
  String get reportDraftAssistPrefix =>
      isAr ? '[مساعدة الإدخال] ' : '[Saisie assistée] ';
  String reportLocationDraftTitle(String nom, String adresse) => isAr
      ? 'مشكلة وصول — $nom\n$adresse\n'
      : 'Signalement accessibilité — $nom\n$adresse\n';
  String get goBack => isAr ? 'رجوع' : 'Retour';
  String get placeName => isAr ? 'اسم المكان' : 'Nom du lieu';
  String get placeNameHint => isAr ? 'مثال: Pharmacie de l\'Espoir' : 'ex. Pharmacie de l\'Espoir';
  String get category => isAr ? 'الفئة' : 'Catégorie';
  String get address => isAr ? 'العنوان' : 'Adresse';
  String get addressHint => isAr ? 'العنوان الكامل' : 'Adresse complète';
  String get city => isAr ? 'المدينة' : 'Ville';
  String get cityHint => isAr ? 'مثال: Tunis' : 'ex. Tunis';
  String get optional => isAr ? 'اختياري' : 'Optionnel';
  String get descriptionHint =>
      isAr ? 'وصف تفصيلي للمكان' : 'Description détaillée du lieu';
  String get images => isAr ? 'الصور' : 'Images';
  String get addImages => isAr ? 'إضافة صور' : 'Ajouter des images';
  String get fromGallery => isAr ? 'من المعرض' : 'Depuis la galerie';
  String get fromCamera => isAr ? 'من الكاميرا' : 'Depuis l\'appareil photo';
  String get submit => isAr ? 'إرسال' : 'Soumettre';
  String get submitLocationDescription =>
      isAr
          ? 'Partagez un lieu accessible pour aider la communauté'
          : 'Partagez un lieu accessible pour aider la communauté';
  String get submitLocationNote =>
      isAr
          ? 'Votre soumission sera examinée par un modérateur avant publication.'
          : 'Votre soumission sera examinée par un modérateur avant publication.';
  String get locationSubmittedSuccess =>
      isAr
          ? 'Lieu soumis avec succès ! Il sera examiné par un modérateur.'
          : 'Lieu soumis avec succès ! Il sera examiné par un modérateur.';
  String get fieldRequired => isAr ? 'Ce champ est requis' : 'Ce champ est requis';
  String get anonymousUser => isAr ? 'Utilisateur anonyme' : 'Utilisateur anonyme';
  String get submittedOn => isAr ? 'Soumis le' : 'Soumis le';
  String get phoneNumberHint => isAr ? 'ex. +216 12 345 678' : 'ex. +216 12 345 678';
  String get openingHoursHint => isAr ? 'ex. Lun-Ven: 9h-18h' : 'ex. Lun-Ven: 9h-18h';
  String get invalidEmailOrPhone => isAr ? 'Email ou téléphone invalide' : 'Email ou téléphone invalide';
  String get invalidPassword => isAr ? 'Mot de passe invalide' : 'Mot de passe invalide';
  String get serverError => isAr ? 'Erreur serveur' : 'Erreur serveur';
  String get invalidData => isAr ? 'Données invalides' : 'Données invalides';
  String get emailAlreadyExists => isAr ? 'Cet email existe déjà' : 'Cet email existe déjà';
  String get phoneAlreadyExists => isAr ? 'Ce numéro existe déjà' : 'Ce numéro existe déjà';
  String get invalidCredentials => isAr ? 'Identifiants invalides' : 'Identifiants invalides';
  String get connectionError => isAr ? 'Erreur de connexion' : 'Erreur de connexion';

  // Posts & Community
  String get communityPosts => isAr ? 'منشورات المجتمع' : 'Publications de la communauté';
  /// Module communauté — où trouver FALC + analyse photo dans les posts.
  String get communityPostsAccessibilityTitle => isAr
      ? ''
      : '';
  String get communityPostsAccessibilityBody => isAr
      ? ''
      : '';
  String get createPost => isAr ? 'إنشاء منشور' : 'Créer un post';
  /// Intro : tous les profils peuvent publier (tactile, voix, tête, vibrations).
  String get postAccessibilityForAllTitle => isAr
      ? 'النشر متاح للجميع'
      : 'Publier : tous les handicaps';
  String get postAccessibilityForAllBody => isAr
      ? 'نموذج كبير وصور. الاهتزازات الثابتة من تبويب طلبات المساعدة.'
      : 'Grand formulaire et photos ci‑dessous. Tête & yeux et voix + vibrations : carte dédiée sur cet écran. Vibrations fixes (menu codé) : onglet Demandes d’aide. Le bouton + peut suivre un raccourci (Profil).';
  String get postAccessibilityModesTitle => isAr
      ? 'طرق بدون لوحة المفاتيح'
      : 'Modes sans tout saisir au clavier';
  String get postAccessibilityModesBody => isAr
      ? 'الرأس والصوت هنا؛ الاهتزازات الثابتة في طلبات المساعدة.'
      : 'Tête & yeux et voix + vibrations ici. Les vibrations fixes (sourd-aveugle) sont dans l’onglet Demandes d’aide.';
  /// Web : les boutons ne sont pas affichés (caméra / micro / vibrateur requis).
  String get postAccessibilityModesWebOnly => isAr
      ? 'الرأس والصوت والاهتزاز: متوفرة في تطبيق الهاتف فقط، وليس في المتصفح.'
      : 'Tête & yeux et voix + vibrations : disponibles dans l’app mobile (Android / iOS), pas dans le navigateur.';
  /// Carte en tête de l’onglet Demandes d’aide : vibrations codées uniquement.
  String get helpAccessibilityPublicationTitle => isAr
      ? 'اهتزازات ثابتة (من تبويب المساعدة)'
      : 'Vibrations fixes (Aides)';
  String get helpAccessibilityPublicationSubtitle => isAr
      ? 'قائمة باهتزازات قصيرة ثم تأكيد — نفس منشور المجتمع.'
      : 'Menu par impulsions puis confirmation (tap dos) — même publication communautaire.';
  /// Écran vibrations codées : rappel que ce n’est pas le seul mode « ajouter un post ».
  String get vibrationPostExplainerTitle => isAr
      ? 'ليس هذا كل خيارات النشر'
      : 'Pas seulement cet écran';
  String get vibrationPostExplainerBody => isAr
      ? 'هنا: طلب مساعدة بالموقع (٣ خيارات). للمنشور الكامل أو الكاميرا أو الصوت + اهتزاز:'
      : 'Ici : demande d’aide géolocalisée (3 choix par vibrations). Pour un post communautaire (texte, photos, type), ou tête & yeux / voix + vibrations, utilisez les boutons ci‑dessous.';
  String get vibrationPostOpenFullForm => isAr
      ? 'منشور كامل (نص + صور)'
      : 'Post complet (texte + photos)';

  // Création de post — flux inclusif (sections)
  String get postCreateSectionPublisher =>
      isAr ? 'من ينشر؟' : 'Qui publie ?';
  String get postCreateForSelf =>
      isAr ? 'لنفسي' : 'Pour moi-même';
  String get postCreateForSomeoneElse =>
      isAr ? 'لشخص آخر' : 'Pour une autre personne';
  String get postCreateSectionInputMode =>
      isAr ? 'طريقة الإدخال' : 'Mode de saisie';
  String get postCreateInputKeyboard => isAr ? 'لوحة المفاتيح' : 'Clavier';
  String get postCreateInputVoice => isAr ? 'صوت' : 'Voix';
  String get postCreateInputHeadEyes => isAr ? 'رأس وعينان' : 'Tête et yeux';
  String get postCreateInputVibration => isAr ? 'اهتزازات' : 'Vibrations';
  String get postCreateInputDeafBlind => isAr ? 'صمم-أعمى' : 'Sourd-aveugle';
  String get postCreateInputCaregiver => isAr ? 'مرافق' : 'Accompagnant';
  String get postCreateShortcutsHint => isAr
      ? 'مسارات مخصصة: تفتح شاشة ثم تعود هنا.'
      : 'Parcours dédiés : ouvre un écran puis revient ici.';
  String get postCreateSectionNature =>
      isAr ? 'طبيعة المنشور' : 'Nature du post';
  String get postCreateNatureSignalement =>
      isAr ? 'إبلاغ' : 'Signalement';
  String get postCreateNatureConseil =>
      isAr ? 'نصيحة' : 'Conseil';
  String get postCreateNatureTemoignage =>
      isAr ? 'شهادة' : 'Témoignage';
  String get postCreateNatureInformation =>
      isAr ? 'معلومات' : 'Information';
  String get postCreateNatureAlerte =>
      isAr ? 'تنبيه' : 'Alerte';
  String get postCreateSectionAudience =>
      isAr ? 'الجمهور المستهدف' : 'Public concerné';
  String get postCreateAudienceAll =>
      isAr ? 'الجميع' : 'Tous';
  String get postCreateAudienceMotor =>
      isAr ? 'إعاقة حركية' : 'Handicap moteur';
  String get postCreateAudienceVisual =>
      isAr ? 'إعاقة بصرية' : 'Handicap visuel';
  String get postCreateAudienceHearing =>
      isAr ? 'إعاقة سمعية' : 'Handicap auditif';
  String get postCreateAudienceCognitive =>
      isAr ? 'إعاقة معرفية' : 'Handicap cognitif';
  String get postCreateAudienceCaregiver =>
      isAr ? 'مرافق' : 'Accompagnant';
  String get postCreateSectionNeeds =>
      isAr ? 'احتياجات إمكانية الوصول' : 'Besoins d’accessibilité';
  String get postCreateSectionContent =>
      isAr ? 'المحتوى' : 'Contenu';
  String get postCreatePresetSuggestions =>
      isAr ? 'اقتراحات جاهزة' : 'Suggestions';
  String get postCreateSectionImages =>
      isAr ? 'صور' : 'Images';
  String get postCreateSectionLocation =>
      isAr ? 'مشاركة الموقع' : 'Partage de position';
  String get postCreateLocationNone =>
      isAr ? 'بدون' : 'Aucune';
  String get postCreateLocationApproximate =>
      isAr ? 'تقريبي' : 'Approximatif';
  String get postCreateLocationPrecise =>
      isAr ? 'دقيق' : 'Précis';
  String get postCreateSectionPreview =>
      isAr ? 'معاينة' : 'Aperçu avant publication';
  String get postCreatePresetThanks =>
      isAr ? 'شكراً للمجتمع على المساعدة.' : 'Merci à la communauté pour l’aide.';
  String get postCreatePresetObstacle =>
      isAr ? 'أبلغ عن عقبة في هذا المكان.' : 'Je signale un obstacle à cet endroit.';
  String get postCreatePresetInfo =>
      isAr ? 'معلومة قد تفيد الآخرين.' : 'Une information utile pour les autres.';
  String get postCreatePresetNeedHelp =>
      isAr ? 'أحتاج نصيحة للتنقل هنا.' : 'J’ai besoin d’un conseil pour me déplacer ici.';

  /// Interrupteur — libellés explicites (même charge utile API : isForAnotherPerson, inputMode).
  String get postCreateSwitchForSelf =>
      isAr ? 'أنشر عن نفسي' : 'Je publie pour moi';
  String get postCreateSwitchForOther =>
      isAr ? 'أنشر عن شخص آخر' : 'Je publie pour quelqu’un d’autre';
  String get postCreatePublisherSwitchTitle =>
      isAr ? 'لمن هذا المنشور؟' : 'Pour qui publiez-vous ?';
  String get postCreatePublisherSubtitleSelf =>
      isAr
          ? 'أنت تنشر تجربتك أو طلبك باسمك.'
          : 'Vous publiez votre expérience ou votre demande en votre nom.';
  String get postCreatePublisherSubtitleOther =>
      isAr
          ? 'تنشر نيابة عن شخص آخر؛ اكتب بوضوح ليفهم المجتمع السياق.'
          : 'Vous publiez pour une autre personne : rédigez clairement pour que la communauté comprenne.';
  String get postCreateCaregiverPostIntro =>
      isAr
          ? 'أنشر نيابة عن شخص آخر (بموافقته عند الإمكان).'
          : 'Je publie pour une autre personne (avec son accord si possible).';
  /// Aide sous le champ texte en mode accompagnant — reste lisible pour tout le monde.
  String get postCreateContentHintCaregiver =>
      isAr
          ? 'صف الوضع والمكان وما تحتاجه الشخص من المجتمع بوضوح.'
          : 'Décrivez la situation, le lieu et ce que la personne attend de la communauté.';
  String get postCreateSemanticSwitchHint =>
      isAr
          ? 'التبديل بين النشر لنفسك أو لشخص آخر.'
          : 'Basculer entre publier pour vous-même ou pour une autre personne.';
  /// Ligne ajoutée à l’aperçu quand le message est relayé.
  String get postCreatePreviewCaregiverNote =>
      isAr
          ? 'هذا المنشور يُنشر من طرف مرافق أو قريب باسم الشخص المعني.'
          : 'Ce message est publié par un accompagnant ou un proche au nom de la personne concernée.';

  String get postCreateSectionNeedsHint =>
      isAr
          ? 'اختر ما يساعد المجتمع على مساعدتك أو تكييف الردود.'
          : 'Indiquez ce qui aide la communauté à vous répondre ou adapter les réponses.';
  String get postCreateNeedAudioHint =>
      isAr
          ? 'مثال: إرشادات صوتية أو وصف شفهي للمسار.'
          : 'Ex. consignes vocales, description orale du chemin.';
  String get postCreateNeedVisualHint =>
      isAr
          ? 'مثال: لافتات واضحة أو تباين ألوان أو إشارات بصرية.'
          : 'Ex. signalétique lisible, contraste, repères visuels.';
  String get postCreateNeedPhysicalHint =>
      isAr
          ? 'مثال: مساعدة للمشي أو رفع أو تجاوز عقبة.'
          : 'Ex. aide pour marcher, franchir un obstacle, se déplacer.';
  String get postCreateNeedSimpleLangHint =>
      isAr
          ? 'مثال: جمل قصيرة وكلمات سهلة.'
          : 'Ex. phrases courtes et mots simples.';

  String get postCreatePresetAppliedSnack =>
      isAr ? 'تم تطبيق النموذج.' : 'Suggestion appliquée.';
  String get postCreatePresetTapHint =>
      isAr
          ? 'اضغط على اقتراح لملء النص وتعديل نوع المنشور والجمهور والاحتياجات.'
          : 'Appuyez sur une suggestion pour remplir le texte et ajuster le type, le public et les besoins.';

  // Libellés courts — puces de suggestion (création de post)
  String get postCreatePresetChipBlocked =>
      isAr ? 'أنا محبوس' : 'Je suis bloqué';
  String get postCreatePresetChipDifficultAccess =>
      isAr ? 'وصول صعب' : 'Accès difficile';
  String get postCreatePresetChipInaccessibleEntrance =>
      isAr ? 'مدخل غير متاح' : 'Entrée inaccessible';
  String get postCreatePresetChipMissingRamp =>
      isAr ? 'بدون منحدر' : 'Rampe absente';
  String get postCreatePresetChipStairsNoHelp =>
      isAr ? 'درج بلا مساعدة' : 'Escaliers sans aide';
  String get postCreatePresetChipNeedOrientation =>
      isAr ? 'أحتاج توجيهاً' : 'J’ai besoin d’orientation';
  String get postCreatePresetChipUsefulAdvice =>
      isAr ? 'نصيحة مفيدة' : 'Conseil utile';
  String get postCreatePresetChipPersonalTestimony =>
      isAr ? 'شهادة شخصية' : 'Témoignage personnel';

  /// Textes générés pour le champ contenu (public communautaire).
  String get postCreatePresetBodyBlocked =>
      isAr
          ? 'أنا محبوس في هذا المكان وأحتاج مساعدة للتحرك أو للخروج. إن أمكن، أشيروا إلى مسار يمكن الوصول إليه.'
          : 'Je suis bloqué·e dans ce lieu et j’ai besoin d’aide pour me déplacer ou sortir. Si vous pouvez, indiquez un itinéraire accessible.';
  String get postCreatePresetBodyDifficultAccess =>
      isAr
          ? 'الوصول إلى هذا المكان صعب بالنسبة لي (منحدرات، عقبات، بُعد). أبلغ عن ذلك لإعلام الآخرين.'
          : 'L’accès à ce lieu est difficile pour moi (pentes, obstacles, distance). Je le signale pour informer les autres personnes.';
  String get postCreatePresetBodyInaccessibleEntrance =>
      isAr
          ? 'المدخل غير متاح: درج، باب ضيق، أو عائق آخر. أبلغ لتحسين الوصول.'
          : 'L’entrée n’est pas accessible : marches, porte étroite ou autre obstacle. Je le signale pour améliorer l’accès.';
  String get postCreatePresetBodyMissingRamp =>
      isAr
          ? 'لا يوجد منحدر أو ميل يمكن الوصول إليه هنا. يصعب ذلك الوصول بالكرسي أو العربة.'
          : 'Il manque une rampe ou une pente accessible ici. Cela complique l’accès en fauteuil ou avec une poussette.';
  String get postCreatePresetBodyStairsNoHelp =>
      isAr
          ? 'لا يوجد مصعد أو بديل للدرج، أو لا أستطيع استخدام الدرج دون مساعدة.'
          : 'Il n’y a pas d’ascenseur ou d’alternative aux escaliers, ou je ne peux pas les utiliser sans aide.';
  String get postCreatePresetBodyNeedOrientation =>
      isAr
          ? 'أحتاج توجيهاً للوصول إلى المدخل أو لمتابعة المسار بشكل يمكن الوصول إليه.'
          : 'J’ai besoin d’orientation pour rejoindre l’entrée ou poursuivre mon trajet de façon accessible.';
  String get postCreatePresetBodyUsefulAdvice =>
      isAr
          ? 'أشارك نصيحة مفيدة من تجربتي لتسهيل الوصول أو الاستقلالية للمعنيين.'
          : 'Je partage un conseil utile tiré de mon expérience pour faciliter l’accès ou l’autonomie des personnes concernées.';
  String get postCreatePresetBodyPersonalTestimony =>
      isAr
          ? 'أشهد عن تجربتي في هذا المكان لإعلام المجتمع (إيجابيات أو نقاط يجب الانتباه لها).'
          : 'Je témoigne de mon expérience à cet endroit pour informer la communauté (points positifs ou points de vigilance).';

  /// Hub Milieux (POST / AIDE / LIEU) — style prototype React.
  String get hubTitle => isAr ? 'مركز المجتمع' : 'Hub Milieux';
  String get hubZonePosts => isAr ? 'منشورات' : 'Posts';
  String get hubZoneAide => isAr ? 'مساعدة' : 'Aide';
  String get hubZoneLieux => isAr ? 'أماكن' : 'Lieux';
  String get communityProches => isAr ? 'أقارب' : 'Proches';
  /// Onglet « lieux à proximité » (pas les contacts).
  String get communityPlacesNearbyTab =>
      isAr ? 'بالجوار' : 'À proximité';
  String get nearbyPlacesTitle =>
      isAr ? 'أماكن قريبة' : 'Lieux à proximité';
  String get readScreen => isAr ? 'قراءة الشاشة' : 'Lire cet écran';
  String get stopReading => isAr ? 'إيقاف القراءة' : 'Arrêter la lecture';
  String get nearbyPlacesHint => isAr
      ? 'ضمن ٤ كم من موقعك، مرتبة حسب الخطر ثم البعد.'
      : 'Dans un rayon de 4 km, tri par niveau de risque puis distance.';
  String nearbyPlacesNoneInRadiusKm(int km) => isAr
      ? 'لا توجد أماكن في نطاق ‎$km‎ كم من موقعك.'
      : 'Aucun lieu dans un rayon de $km km autour de vous.';
  String get nearbyPlacesNeedLocation => isAr
      ? 'فعّل خدمات الموقع وامنح الإذن لعرض الأماكن القريبة.'
      : 'Activez la localisation et autorisez l’app pour voir les lieux proches.';
  String get nearbyPlacesWebUnavailable => isAr
      ? 'الأماكن القريبة متاحة في تطبيق الهاتف فقط.'
      : 'Les lieux à proximité sont disponibles dans l’app mobile.';
  String nearbyPlacesKmOneDecimal(double km) => isAr
      ? '${km.toStringAsFixed(1)} كم'
      : '${km.toStringAsFixed(1)} km';
  String nearbyPlacesMeters(int m) =>
      isAr ? '$m م' : '$m m';
  String get riskDanger => isAr ? 'خطر' : 'Danger';
  String get riskCaution => isAr ? 'يتطلب تحقق' : 'A vérifier';
  String get riskSafe => isAr ? 'معلومات' : 'Info';
  String nearbyPlacesAudioIntro(int count) => isAr
      ? 'تم العثور على $count أماكن قريبة.'
      : '$count lieux à proximité trouvés.';
  String nearbyPlaceAudioItem(String name, String category, String distance) => isAr
      ? '$name. $category. المسافة $distance.'
      : '$name. $category. Distance $distance.';
  String locationDetailsAudio(
    String name,
    String address,
    String category,
    String? description,
  ) => isAr
      ? 'تفاصيل المكان: $name. الفئة: $category. العنوان: $address. ${description ?? ''}'
      : 'Détails du lieu : $name. Catégorie : $category. Adresse : $address. ${description ?? ''}';
  String get communityCircleOfTrust => isAr ? 'دائرة الثقة' : 'Cercle de confiance';
  String get communitySearchCloseOne =>
      isAr ? 'ابحث عن قريب…' : 'Rechercher un proche…';
  String get communityNoCloseOne =>
      isAr ? 'لا يوجد أقارب بعد.' : 'Aucun proche pour le moment.';
  String get communityAddCloseOne => isAr ? 'إضافة قريب' : 'Ajouter un proche';
  String get communityDistanceUnknown => isAr ? '— km' : '— km';
  String get communitySurveillanceTitle =>
      isAr ? 'وضع المراقبة' : 'Mode Surveillance';
  String get communitySurveillanceBody => isAr
      ? 'سيستلم أقاربك موقعك إذا لم تؤكد وصولك.'
      : 'Vos proches reçoivent votre position si vous ne confirmez pas votre arrivée.';
  String get communityShareTrip =>
      isAr ? 'مشاركة مساري' : 'Partager mon trajet';
  String get communitySurveillanceSoon =>
      isAr ? 'قريباً' : 'Bientôt disponible';
  String get call => isAr ? 'اتصال' : 'Appeler';
  String get message => isAr ? 'رسالة' : 'Message';
  String get hubMute => isAr ? 'كتم' : 'Muet';
  String get hubUnmute => isAr ? 'تشغيل الصوت' : 'Activer';
  String get hubPostsSubtitle => isAr
      ? 'الذكاء الجماعي لسلامتك.'
      : 'L’intelligence collective pour votre sécurité.';
  String get hubOpenCommunityPosts => isAr ? 'فتح المنشورات' : 'Ouvrir les posts';
  String get hubDangerAlert => isAr ? 'خطر' : 'Alerte danger';
  String get hubSeeOnMap => isAr ? 'الخريطة' : 'Voir sur carte';
  String get hubVigilance => isAr ? 'انتباه' : 'Vigilance';
  String get hubLieuBody => isAr
      ? 'ملاحظة: تم الإبلاغ عن عائق قريبًا. استخدم الدليل الصوتي.'
      : 'Note : un obstacle a été signalé récemment à proximité. Le guide vocal aide au contournement.';
  String get hubOpenPlaces => isAr ? 'فتح الأماكن' : 'Ouvrir les lieux';
  String get hubAideTitle => isAr ? 'SOS لمسي' : 'SOS tactile';
  String get hubAideSubtitle => isAr
      ? 'اضغط في أي مكان'
      : 'Appui n’importe où';
  String get hubNetworkTitle => isAr ? 'شبكة M3AK' : 'Réseau M3AK';
  String get hubNetworkBody => isAr
      ? 'مشاركة الموقع مع المتطوعين القريبين.'
      : 'Position partagée avec des bénévoles proches.';
  String get hubOpenHelpRequests =>
      isAr ? 'فتح طلبات المساعدة' : 'Ouvrir demandes d’aide';
  String get hubNoRecentPost => isAr ? 'لا منشور حديث.' : 'Aucun signalement récent.';
  String get hubNoPlace => isAr ? 'لا مكان قريب.' : 'Aucun lieu proche.';

  // Voice guide phrases
  String get hubVoiceAideIdle => isAr
      ? 'منطقة المساعدة. اضغط ثلاث مرات للإغاثة الفورية.'
      : 'Zone d’assistance. Tapez trois fois n’importe où pour un secours immédiat.';
  String hubVoiceAideTap(int n) => isAr ? 'تم استقبال $n.' : '$n tape reçue.';
  String hubVoicePost(String danger) => isAr
      ? 'منطقة المجتمع. الإشارة الحالية: $danger.'
      : 'Zone Communauté. Signalement actuel : $danger.';
  String hubVoiceLieu(String place) => isAr
      ? 'منطقة الأماكن. أنت قريب من: $place.'
      : 'Zone Lieux. Vous êtes près de : $place.';

  // Hub v2 (aligné prototype Gemini)
  String get hubAudioMuted => isAr ? 'الصوت مكتوم' : 'Audio muet';
  String hubAudioActive(String zoneLabel) => isAr
      ? 'الدليل الصوتي نشط — $zoneLabel'
      : 'Guide vocal actif — $zoneLabel';
  String get hubAlternativeRoute => isAr
      ? 'مسار بديل: شارع جانبي (مناسب).'
      : 'Passage par la rue latérale (Accessible).';
  String hubPostsHintSafe(String safeLocation) => isAr
      ? 'ملجأ قريب: $safeLocation.'
      : 'Refuge proche : $safeLocation.';
  String get hubVolunteersLoading => isAr ? 'بحث عن متطوعين قريبين…' : 'Recherche de bénévoles proches…';
  String hubVolunteersCount(int? n) {
    if (n == null) {
      return isAr ? 'شبكة الطوارئ جاهزة.' : 'Réseau d’urgence prêt.';
    }
    return isAr ? '$n متطوع قريب.' : '$n Anges Gardiens autour de vous.';
  }
  String get postShortcutSectionTitle =>
      isAr ? 'زر + في المجتمع' : 'Bouton + (communauté)';
  String get postShortcutFormTitle =>
      isAr ? 'النموذج العادي' : 'Formulaire classique';
  String get postShortcutFormSubtitle => isAr
      ? 'فتح شاشة الإنشاء المعتادة.'
      : 'Ouvre l’écran de création habituel (tactile ou vocal).';
  String get postShortcutHeadTitle =>
      isAr ? 'الرأس والعيون' : 'Caméra tête & yeux';
  String get postShortcutHeadSubtitle => isAr
      ? 'للشلل الشديد: الكاميرا الأمامية مباشرة.'
      : 'Handicap moteur lourd : caméra frontale tout de suite.';
  String get postShortcutVibrationTitle =>
      isAr ? 'الاهتزازات' : 'Vibrations codées';
  String get postShortcutVibrationSubtitle => isAr
      ? 'قائمة بالاهتزازات (مثلاً صمم-بكم).'
      : 'Menu par impulsions (ex. sourd-aveugle) — raccourci depuis l’onglet Aides.';
  String get postShortcutVoiceVibTitle =>
      isAr ? 'صوت + اهتزازات' : 'Voix + vibrations';
  String get postShortcutSourdAveugleTitle => isAr
      ? 'صمم‑بكم'
      : 'Sourd‑aveugle';
  String get postShortcutVoiceVibSubtitle => isAr
      ? 'إملاء ثم اهتزاز لكل كلمة.'
      : 'Dictée puis une vibration par mot — depuis l’onglet Aides.';
  String get createPostDescription => isAr ? 'Partagez vos pensées avec la communauté' : 'Partagez vos pensées avec la communauté';
  String get postType => isAr ? 'نوع المنشور' : 'Type de post';
  String get allTypes => isAr ? 'الكل' : 'Tous';
  String get content => isAr ? 'المحتوى' : 'Contenu';
  String get postContentHint => isAr ? 'Écrivez votre message...' : 'Écrivez votre message...';
  String get shareYourThoughts => isAr ? 'Partagez vos pensées avec la communauté' : 'Partagez vos pensées avec la communauté';
  String get publish => isAr ? 'نشر' : 'Publier';
  String get postNote => isAr ? 'Votre post sera visible par tous les membres de la communauté.' : 'Votre post sera visible par tous les membres de la communauté.';
  String get postCreatedSuccess => isAr ? 'Post créé avec succès !' : 'Post créé avec succès !';
  String get noPosts => isAr ? 'Aucun post trouvé' : 'Aucun post trouvé';
  String get beFirstToPost => isAr ? 'Soyez le premier à publier !' : 'Soyez le premier à publier !';
  String get errorLoadingPosts => isAr ? 'Erreur lors du chargement des posts' : 'Erreur lors du chargement des posts';
  String get postDetails => isAr ? 'Détails du post' : 'Détails du post';
  String get comments => isAr ? 'التعليقات' : 'Commentaires';
  String get writeComment => isAr ? 'Écrivez un commentaire...' : 'Écrivez un commentaire...';
  String get noComments => isAr ? 'Aucun commentaire pour le moment' : 'Aucun commentaire pour le moment';
  String get errorLoadingComments => isAr ? 'Erreur lors du chargement des commentaires' : 'Erreur lors du chargement des commentaires';
  String get errorLoadingPost => isAr ? 'Erreur lors du chargement du post' : 'Erreur lors du chargement du post';
  String get page => isAr ? 'صفحة' : 'Page';
  String minimumCharacters(int n) => isAr ? 'Minimum $n caractères requis' : 'Minimum $n caractères requis';

  // Help Requests
  String get helpRequests => isAr ? 'طلبات المساعدة' : 'Demandes d\'aide';
  String get createHelpRequest => isAr ? 'إنشاء طلب مساعدة' : 'Créer une demande d\'aide';
  String get createHelpRequestDescription => isAr ? 'Demandez de l\'aide à la communauté' : 'Demandez de l\'aide à la communauté';
  String get helpRequestDescriptionHint => isAr ? 'Décrivez votre besoin...' : 'Décrivez votre besoin...';
  String get describeYourNeed => isAr ? 'Décrivez clairement votre besoin' : 'Décrivez clairement votre besoin';
  String get location => isAr ? 'الموقع' : 'Localisation';
  String get currentLocation => isAr ? 'الموقع الحالي' : 'Position actuelle';
  String get useCurrentLocation => isAr ? 'استخدام الموقع الحالي' : 'Utiliser ma position';
  String get locationHelpMessage => isAr ? 'Votre position sera partagée pour permettre aux bénévoles de vous trouver.' : 'Votre position sera partagée pour permettre aux bénévoles de vous trouver.';
  String get shareLocationWithPost => isAr
      ? 'مشاركة موقعي مع المنشور'
      : 'Partager ma localisation avec ce post';
  String get shareLocationPostHint => isAr
      ? 'سيساعد ذلك المجتمع على فهم المكان بدقة.'
      : 'Cela aide la communauté à comprendre le lieu exact du signalement.';
  String get locationAttached => isAr
      ? 'تم إرفاق الموقع بالمنشور.'
      : 'Position attachée au post.';
  String get locationUpdated =>
      isAr ? 'تم تحديث الموقع.' : 'Position mise à jour.';
  String get locationUnavailable => isAr
      ? 'تعذر الحصول على الموقع.'
      : 'Position indisponible. Activez la localisation et autorisez l’app.';
  /// Raccourci volume+ sur l’onglet Demandes d’aide (Android).
  String get helpVolumeShortcutHint => isAr
      ? 'Android: في تبويب طلبات المساعدة، اضغط رفع الصوت لإرسال طلب مع موقعك.'
      : 'Android : sur cet onglet, appuyez sur volume+ pour envoyer une demande d’aide avec votre position actuelle.';
  String get helpRequestNote => isAr ? 'Les membres de la communauté pourront voir votre demande et vous aider.' : 'Les membres de la communauté pourront voir votre demande et vous aider.';
  String get helpRequestCreatedSuccess => isAr ? 'Demande d\'aide créée avec succès !' : 'Demande d\'aide créée avec succès !';
  String get noHelpRequests => isAr ? 'Aucune demande d\'aide trouvée' : 'Aucune demande d\'aide trouvée';
  String get beFirstToHelp => isAr ? 'Soyez le premier à demander de l\'aide !' : 'Soyez le premier à demander de l\'aide !';
  String get errorLoadingHelpRequests => isAr ? 'Erreur lors du chargement des demandes' : 'Erreur lors du chargement des demandes';

  // Création demande d’aide — flux inclusif
  String get helpCreateSectionHowTitle =>
      isAr ? 'كيف تريد طلب المساعدة؟' : 'Comment voulez-vous demander de l’aide ?';
  String get helpCreateSectionWhatTitle =>
      isAr ? 'أي نوع من المساعدة؟' : 'Quel type d’aide ?';
  String get helpCreateSectionNeedsTitle =>
      isAr ? 'احتياجات إمكانية الوصول' : 'Besoins d’accessibilité';
  String get helpCreateSectionPreviewTitle =>
      isAr ? 'معاينة قبل الإرسال' : 'Aperçu avant envoi';
  String get helpCreateModeText =>
      isAr ? 'كتابة' : 'Texte';
  String get helpCreateModeVoice =>
      isAr ? 'صوت' : 'Voix';
  String get helpCreateModeTap =>
      isAr ? 'نقر سريع' : 'Préréglages rapides';
  String get helpCreateModeHaptic =>
      isAr ? 'لمسي' : 'Haptique';
  String get helpCreateModeCaregiver =>
      isAr ? 'مرافق' : 'Accompagnant';
  String get helpCreateScenarioBlocked =>
      isAr ? 'محبوس' : 'Je suis bloqué';
  String get helpCreateScenarioLost =>
      isAr ? 'تائه' : 'Je suis perdu';
  String get helpCreateScenarioCannotEnter =>
      isAr ? 'لا أستطيع الدخول' : 'Je ne peux pas entrer';
  String get helpCreateScenarioEscort =>
      isAr ? 'مرافقة' : 'J’ai besoin d’accompagnement';
  String get helpCreateScenarioCommunicate =>
      isAr ? 'التواصل' : 'J’ai besoin d’aide pour communiquer';
  String get helpCreateScenarioDanger =>
      isAr ? 'وضع خطير' : 'Situation dangereuse';
  String get helpCreateNeedAudio =>
      isAr ? 'إرشادات صوتية' : 'Guidance audio';
  String get helpCreateNeedVisual =>
      isAr ? 'دعم بصري' : 'Support visuel';
  String get helpCreateNeedPhysical =>
      isAr ? 'مساعدة جسدية' : 'Assistance physique';
  String get helpCreateNeedSimpleLang =>
      isAr ? 'لغة بسيطة' : 'Langage simple';
  String get helpCreateSelectScenario =>
      isAr ? 'اختر نوع المساعدة' : 'Choisissez un type d’aide';
  String get helpCreateVoiceHint =>
      isAr ? 'استخدم لوحة المفاتيح أو الإملاء' : 'Utilisez le clavier ou la dictée du système';

  /// Dictée — états (écran demande d’aide)
  String get helpVoiceStateUninitialized =>
      isAr ? 'جاري تجهيز الميكروفون…' : 'Préparation du microphone…';
  String get helpVoiceStateReady =>
      isAr ? 'جاهز. اضغط على الميكروفون للتحدث.' : 'Prêt. Appuyez sur le microphone pour parler.';
  String get helpVoiceStateListening =>
      isAr ? 'يستمع… تحدث بوضوء.' : 'Écoute en cours… Parlez distinctement.';
  String get helpVoiceStateRecognized =>
      isAr ? 'تم التعرف على النص. يمكنك تعديله أو الإرسال مع اختيار سريع.'
          : 'Texte reconnu. Vous pouvez le corriger ou envoyer avec un préréglage.';
  String get helpVoiceMicSemanticsStart =>
      isAr ? 'بدء التحدث بالصوت' : 'Démarrer la dictée vocale';
  String get helpVoiceMicSemanticsStop =>
      isAr ? 'إيقاف الاستماع' : 'Arrêter l’écoute et valider le texte reconnu';
  String get helpVoiceRetry =>
      isAr ? 'إعادة المحاولة' : 'Réessayer';
  String get helpVoiceWebHint =>
      isAr
          ? 'على الويب قد يطلب المتصفح إذن الميكروفون.'
          : 'Sur le web, le navigateur peut demander l’accès au microphone.';
  String get helpVoiceShortOkHint =>
      isAr
          ? 'يمكنك الإرسال حتى مع نص قصير إذا اخترت نوع المساعدة أعلاه.'
          : 'Vous pouvez envoyer même avec un texte court si vous avez choisi un type d’aide ci-dessus.';

  String helpVoiceErrorMessage(String? code) {
    switch (code) {
      case 'microphone_denied':
        return isAr
            ? 'تم رفض الميكروفون. اسمح بالوصول من الإعدادات.'
            : 'Microphone refusé. Autorisez l’accès dans les paramètres.';
      case 'init_failed':
        return isAr
            ? 'تعذر تشغيل التعرف على الكلام على هذا الجهاز.'
            : 'Reconnaissance vocale indisponible sur cet appareil.';
      default:
        if (code == null || code.isEmpty) {
          return isAr ? 'حدث خطأ.' : 'Une erreur s’est produite.';
        }
        return isAr
            ? 'خطأ في التعرف على الصوت: $code'
            : 'Erreur de reconnaissance vocale : $code';
    }
  }
  String get helpCreatePreviewNote =>
      isAr ? 'النص النهائي قد يُكمَل على الخادم' : 'Le texte final peut être complété côté serveur';

  // Préréglages rapides — libellés (FR / AR)
  String get helpCreateQuickBlocked =>
      isAr ? 'أنا محبوس' : 'Je suis bloqué';
  String get helpCreateQuickLost =>
      isAr ? 'أنا تائه' : 'Je suis perdu';
  String get helpCreateQuickCannotFindEntrance =>
      isAr ? 'لا أجد المدخل' : 'Je ne trouve pas l’entrée';
  String get helpCreateQuickMobilityHelp =>
      isAr ? 'أحتاج مساعدة للتنقل' : 'J’ai besoin d’aide pour me déplacer';
  String get helpCreateQuickOrientationHelp =>
      isAr ? 'أحتاج مساعدة للتوجه' : 'J’ai besoin d’aide pour m’orienter';
  String get helpCreateQuickCommunicationHelp =>
      isAr ? 'أحتاج مساعدة للتواصل' : 'J’ai besoin d’aide pour communiquer';
  String get helpCreateQuickForAnotherPerson =>
      isAr ? 'أطلب المساعدة لشخص آخر' : 'Je demande de l’aide pour une autre personne';
  String get helpCreateQuickDanger =>
      isAr ? 'وضع خطير' : 'Situation dangereuse';

  /// Phrase d’aperçu (alignée sur le message serveur quand un préréglage est utilisé).
  String get helpCreateQuickPreviewBlocked => isAr
      ? 'أحتاج مساعدة في المكان: يبدو الوصول صعبًا.'
      : 'Je suis bloqué. L’accès semble difficile ou inaccessible. J’ai besoin d’aide sur place.';
  String get helpCreateQuickPreviewLost => isAr
      ? 'أنا تائه وأحتاج مساعدة للتوجه.'
      : 'Je suis perdu et j’ai besoin d’aide pour m’orienter.';
  String get helpCreateQuickPreviewCannotFindEntrance => isAr
      ? 'لا أستطيع الوصول أو إيجاد المدخل. أحتاج مساعدة.'
      : 'Je n’arrive pas à accéder ou à trouver l’entrée. J’ai besoin d’aide.';
  String get helpCreateQuickPreviewMobilityHelp => isAr
      ? 'أحتاج مساعدة للتنقل أو مرافقة.'
      : 'J’ai besoin d’être accompagné·e pour me déplacer ou pour communiquer.';
  String get helpCreateQuickPreviewOrientationHelp => isAr
      ? 'أحتاج مساعدة للتوجه وإيجاد الطريق.'
      : 'Je suis perdu·e et j’ai besoin d’aide pour m’orienter.';
  String get helpCreateQuickPreviewCommunicationHelp => isAr
      ? 'أحتاج مساعدة للتواصل أو لأن يفهمني الآخرون.'
      : 'J’ai besoin d’aide pour communiquer ou me faire comprendre.';
  String get helpCreateQuickPreviewForAnotherPerson => isAr
      ? 'أطلب مساعدة لشخص آخر.'
      : 'Je demande de l’aide pour une personne.';
  String get helpCreateQuickPreviewDanger => isAr
      ? 'أحتاج مساعدة عاجلة متعلقة بالصحة أو الراحة.'
      : 'J’ai besoin d’aide liée à un problème de santé ou de confort immédiat.';

  /// Titre court au-dessus de la phrase d’aperçu principale.
  String get helpCreatePreviewMainMessageTitle =>
      isAr ? 'الرسالة (معاينة)' : 'Message principal (aperçu)';

  /// Libellé accessibilité (lecteur d’écran) : « Priorité : … ».
  String get helpRequestPrioritySemanticLabel =>
      isAr ? 'الأولوية' : 'Priorité';

  String get helpRequestDetailTitle =>
      isAr ? 'تفاصيل طلب المساعدة' : 'Détail de la demande d’aide';

  String get helpRequestPriorityReasonHeading =>
      isAr ? 'تفسير الأولوية' : 'Justification de la priorité';

  String get helpRequestDescriptionHeading =>
      isAr ? 'الرسالة' : 'Message';
  String get helpRequestAccessibilityHeading =>
      isAr ? 'احتياجات إمكانية الوصول' : 'Besoins d’accessibilité';
  String get helpRequestInputModeHeading =>
      isAr ? 'طريقة الإدخال' : 'Mode de saisie';
  String get helpRequestHelpTypeHeading =>
      isAr ? 'نوع الطلب' : 'Type de besoin';
  String get helpRequestCaregiverBadge =>
      isAr ? 'لشخص آخر / مرافق' : 'Pour une autre personne (accompagnant)';
  String get helpRequestCaregiverSemantic =>
      isAr ? 'طلب لصالح شخص آخر أو من مرافق' : 'Demande pour une autre personne ou par un accompagnant';
  String get helpRequestSummaryFallback =>
      isAr ? '(لا يوجد نص؛ تم إنشاء الرسالة تلقائياً)' : '(Aucun texte libre ; message généré automatiquement)';
  String get helpRequestDeveloperSignalsTitle =>
      isAr ? 'إشارات الأولوية (مطور)' : 'Signaux de priorité (développeur)';
  String get helpRequestDeveloperSignalsSubtitle =>
      isAr ? 'للتصحيح فقط' : 'À des fins de débogage uniquement';

  String get helpRequestAcceptLabel =>
      isAr ? 'قبول' : 'Accepter';
  String get helpRequestAcceptThisLabel =>
      isAr ? 'قبول هذا الطلب' : 'Accepter cette demande';
  String get helpRequestAcceptingLabel =>
      isAr ? 'جاري…' : 'Patientez…';

  String helpRequestHelpTypeLabel(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'mobility':
        return isAr ? 'تنقل' : 'Mobilité';
      case 'orientation':
        return isAr ? 'توجيه' : 'Orientation';
      case 'communication':
        return isAr ? 'تواصل' : 'Communication';
      case 'medical':
        return isAr ? 'صحة / طوارئ' : 'Santé / urgence';
      case 'escort':
        return isAr ? 'مرافقة' : 'Accompagnement';
      case 'unsafe_access':
        return isAr ? 'وصول / خطر' : 'Accès / sécurité';
      case 'other':
        return isAr ? 'آخر' : 'Autre';
      default:
        if (raw != null && raw.trim().isNotEmpty) return raw.trim();
        return isAr ? 'غير محدد' : 'Non précisé';
    }
  }

  String helpRequestInputModeLabel(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'text':
        return isAr ? 'كتابة' : 'Texte';
      case 'voice':
        return isAr ? 'صوت' : 'Voix';
      case 'tap':
        return isAr ? 'نقر' : 'Préréglages';
      case 'haptic':
        return isAr ? 'لمسي' : 'Haptique';
      case 'volume_shortcut':
        return isAr ? 'زر الصوت' : 'Raccourci volume';
      case 'caregiver':
        return isAr ? 'مرافق' : 'Accompagnant';
      default:
        if (raw != null && raw.trim().isNotEmpty) return raw.trim();
        return isAr ? 'غير محدد' : 'Non précisé';
    }
  }

  /// Résumé des cases à cocher inclusives (pour affichage).
  String helpRequestNeedsSummary({
    required bool? audio,
    required bool? visual,
    required bool? physical,
    required bool? simpleLang,
  }) {
    final parts = <String>[];
    if (audio == true) parts.add(helpCreateNeedAudio);
    if (visual == true) parts.add(helpCreateNeedVisual);
    if (physical == true) parts.add(helpCreateNeedPhysical);
    if (simpleLang == true) parts.add(helpCreateNeedSimpleLang);
    if (parts.isEmpty) {
      return isAr ? 'لم يُذكر' : 'Non précisé';
    }
    return parts.join(isAr ? '، ' : ', ');
  }

  /// Étiquette affichée sur le badge (texte explicite, pas seulement la couleur).
  String helpRequestPriorityLabel(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'critical':
        return isAr ? 'حرج' : 'CRITIQUE';
      case 'high':
        return isAr ? 'عاجل' : 'URGENT';
      case 'medium':
        return isAr ? 'متوسط' : 'MOYEN';
      case 'low':
        return isAr ? 'منخفض' : 'FAIBLE';
      default:
        return '';
    }
  }

  /// Module aide tactile (3 taps → SOS).
  String get hapticHelpTitle =>
      isAr ? 'مساعدة لمسية' : 'Aide tactile — SOS';
  String get hapticHelpSubtitle => isAr
      ? 'مساعدة حرجة — نقرات مشفرة'
      : 'Assistance critique — tapotements codés';
  String get hapticHelpCardSubtitle => isAr
      ? 'ثلاث نقرات على المنطقة لإرسال تنبيه طوارئ مع موقعك.'
      : 'Trois taps sur la zone pour envoyer une alerte SOS avec votre position.';
  String get hapticHelpTapIntro => isAr
      ? 'اضغط في أي مكان للمساعدة'
      : 'Appuyez n’importe où sur la zone pour demander de l’aide';
  String hapticHelpTapCount(int n) => isAr
      ? 'تم اكتشاف $n نقرة…'
      : '$n tap${n > 1 ? 's' : ''} détecté${n > 1 ? 's' : ''}…';
  String get hapticHelpSosSentBanner =>
      isAr ? '🚨 تم إرسال تنبيه الطوارئ' : '🚨 SOS ENVOYÉ';
  String get hapticHelpTtsEntry => isAr
      ? 'وضع المساعدة اللمسية مفعّل. انقر ثلاث مرات للإغاثة الفورية.'
      : 'Mode aide tactile activé. Tapez trois fois pour un secours immédiat.';
  String get hapticHelpTtsAfterSos => isAr
      ? 'تم إرسال التنبيه. يمكن إبلاغ مرافق بموقعك.'
      : 'Alerte envoyée. Un accompagnant peut être prévenu de votre position.';
  String get hapticHelpCallContact =>
      isAr ? 'الاتصال بقريب' : 'Appeler un proche';
  String get hapticHelpVocalGuide =>
      isAr ? 'دليل صوتي' : 'Guide vocal';
  String get hapticHelpSosApiOk =>
      isAr ? 'تم تسجيل تنبيه الطوارئ.' : 'Alerte SOS enregistrée.';
  String get hapticHelpWebNotice => isAr
      ? 'الاهتزاز والوصول الكامل للموقع على التطبيق فقط.'
      : 'Vibrations et SOS géolocalisé : utilisez l’app sur téléphone.';

  /// Hub M3AK Secours (SOS + réseau + simulation bénévole).
  String get helpHubTitle =>
      isAr ? 'مساعدة M3AK' : 'M3AK Secours';
  String get helpHubPanelNetwork =>
      isAr ? 'شبكة قريبة' : 'Voir le réseau';
  String get helpHubPanelBackSos =>
      isAr ? 'رجوع SOS' : 'Retour SOS';
  String get helpHubDemoBadge => isAr
      ? 'عرض توضيحي'
      : 'Démo (démo web uniquement)';
  String get helpHubWaitingResponder => isAr
      ? 'في انتظار أن يضغط متطوع «أنا قادم» في قائمة التنبيهات القريبة.'
      : 'En attente qu’un aidant appuie sur « M’y rendre » dans les alertes à proximité.';
  String get helpHubPollTimeout => isAr
      ? 'لا رد بعد عدة دقائق. اتصل بقريب أو أعد المحاولة.'
      : 'Aucun secours confirmé pour l’instant. Contactez un proche ou réessayez.';
  String helpHubResponderOnWay(String name) {
    final n = name.trim().isEmpty ? 'Un accompagnant' : name;
    return isAr
        ? 'خبر سار: $n في الطريق لمساعدتك.'
        : 'Bonne nouvelle : $n est en route pour vous aider.';
  }

  String helpHubConfirmedResponder(String name) {
    final n = name.trim().isEmpty ? 'Un accompagnant' : name;
    return isAr ? '$n في الطريق.' : '$n est en route pour vous aider.';
  }

  String get sosMyWayButton =>
      isAr ? 'أنا قادم' : 'M’y rendre';
  String get sosMyWayOk => isAr ? 'تم التسجيل.' : 'Vous avez pris en charge cette alerte.';
  String get helpHubTtsSearchVoluntary => isAr
      ? 'تم إرسال التنبيه. البحث عن متطوع قريب.'
      : 'Alerte envoyée. Recherche d’un accompagnant ou bénévole à proximité.';
  String get helpHubTtsDemoArrival => isAr
      ? 'خبر جيد: يوجد مساعد في الطريق إليك.'
      : 'Bonne nouvelle : un accompagnant a pris en charge votre alerte. Restez sur place si possible.';
  String get helpHubStatusReady =>
      isAr ? 'جاهز' : 'Prêt';
  String get helpHubStatusWaiting =>
      isAr ? 'في الانتظار' : 'En attente';
  String get helpHubStatusConfirmed =>
      isAr ? 'مساعدة في الطريق' : 'Secours en route';
  String get helpHubNetworkOk =>
      isAr ? 'الشبكة نشطة' : 'Réseau proximité OK';
  String get helpHubNearbyTitle =>
      isAr ? 'تنبيهات قريبة' : 'Alertes à proximité';
  String get helpHubNearbySubtitle => isAr
      ? 'من API findNearby — نفس منطقة الخطر يمكن أن تُنشأ من منشور حرج.'
      : 'API findNearby — un post « danger critique » avec position crée aussi une alerte ici.';
  String get helpHubNearbyEmpty => isAr
      ? 'لا تنبيهات في هذه المنطقة.'
      : 'Aucune alerte SOS dans ce périmètre pour l’instant.';
  String get helpHubNearbyLoadError =>
      isAr ? 'تعذر تحميل القائمة.' : 'Impossible de charger les alertes.';
  String get helpHubFooter =>
      isAr ? 'Ma3ak Security Engine v2.5' : 'Ma3ak Security Engine v2.5';
  String get helpHubResetSos =>
      isAr ? 'تنبيه جديد' : 'Nouvelle alerte';
  String get helpHubConfirmedLine1 => isAr
      ? 'تم قبول طلبك.'
      : 'Votre alerte est prise en charge.';
  String get helpHubConfirmedLine2 => isAr
      ? 'ابقَ في مكانك إن أمكن.'
      : 'Restez sur place si vous le pouvez.';
  String get helpHubSosLabel =>
      isAr ? 'SOS' : 'SOS';
  String get helpHubSosSending =>
      isAr ? 'جاري الإرسال…' : 'Envoi…';
  String get helpHubSosOk =>
      isAr ? 'OK' : 'OK';
  String helpHubTapProgress(int n, int max) => isAr
      ? '$n / $max'
      : '$n / $max';
  String get helpHubCardStatLabel =>
      isAr ? 'الحالة' : 'Statut';
  String get helpHubCardNetworkLabel =>
      isAr ? 'الشبكة' : 'Réseau';
}
