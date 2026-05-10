from __future__ import annotations

ACTION_LABELS = ["create_post", "create_help_request"]

POST_NATURE_LABELS = ["signalement", "conseil", "temoignage", "information", "alerte", "none"]
POST_TARGET_AUDIENCE_LABELS = ["all", "motor", "visual", "hearing", "cognitive", "caregiver", "none"]
POST_INPUT_MODE_LABELS = ["keyboard", "voice", "headEyes", "vibration", "deafBlind", "caregiver", "none"]
LOCATION_SHARING_MODE_LABELS = ["none", "approximate", "precise"]
DANGER_LEVEL_LABELS = ["none", "low", "medium", "critical"]

HELP_TYPE_LABELS = ["mobility", "orientation", "communication", "medical", "escort", "unsafe_access", "other", "none"]
REQUESTER_PROFILE_LABELS = ["visual", "motor", "hearing", "cognitive", "caregiver", "unknown", "none"]
HELP_INPUT_MODE_LABELS = ["text", "voice", "tap", "haptic", "volume_shortcut", "caregiver", "none"]
PRESET_MESSAGE_KEY_LABELS = ["blocked", "lost", "cannot_reach", "medical_urgent", "escort", "none"]

BOOL_COLUMNS = [
    "needsAudioGuidance",
    "needsVisualSupport",
    "needsPhysicalAssistance",
    "needsSimpleLanguage",
    "isForAnotherPerson",
]

LABEL_COLUMNS = [
    "actionType",
    "postNature",
    "targetAudience",
    "postInputMode",
    "locationSharingMode",
    "dangerLevel",
    "helpType",
    "requesterProfile",
    "helpInputMode",
    "presetMessageKey",
    *BOOL_COLUMNS,
]

POST_ONLY_COLUMNS = [
    "postNature",
    "targetAudience",
    "postInputMode",
    "locationSharingMode",
    "dangerLevel",
]

HELP_ONLY_COLUMNS = [
    "helpType",
    "requesterProfile",
    "helpInputMode",
    "presetMessageKey",
]

