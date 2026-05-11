class M3akCreatePostLaunch {
  const M3akCreatePostLaunch({
    required this.initialContent,
    this.autoOpenCamera = false,
    this.autoPublishAfterCamera = false,
    /// Android : annonce « galerie », Volume+ ouvre la galerie ; sinon après délai → caméra.
    this.accessibilityAnnounceGalleryVolumeOrCameraFallback = false,
  });

  final String initialContent;
  final bool autoOpenCamera;
  final bool autoPublishAfterCamera;

  /// Prioritaire sur [autoOpenCamera] si les deux sont vrais.
  final bool accessibilityAnnounceGalleryVolumeOrCameraFallback;
}

