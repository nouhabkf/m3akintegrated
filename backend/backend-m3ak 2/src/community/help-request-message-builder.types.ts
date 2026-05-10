import type {
  HelpRequestHelpType,
  HelpRequestInputMode,
  HelpRequestRequesterProfile,
} from './enums/help-request-inclusion.enum';

/**
 * Entrée pour construire la description finale stockée en base.
 * Tous les champs sont optionnels sauf usage conjoint (voir service).
 */
export interface HelpRequestMessageBuilderInput {
  description?: string;
  helpType?: HelpRequestHelpType;
  inputMode?: HelpRequestInputMode;
  requesterProfile?: HelpRequestRequesterProfile;
  needsAudioGuidance?: boolean;
  needsVisualSupport?: boolean;
  needsPhysicalAssistance?: boolean;
  needsSimpleLanguage?: boolean;
  isForAnotherPerson?: boolean;
  presetMessageKey?: string;
}
