// Transitional shim: AiTriageService was renamed AiTaggingService (plan F5, D-07).
// Kept so existing imports keep compiling; both names refer to the same class.
export { AiTaggingService, AiTaggingService as AiTriageService } from './ai-tagging.service';
