import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';
import { AiTaggingService, toPublicTags } from '../src/modules/ai/services/ai-tagging.service';
import { IdiomDictionaryService } from '../src/modules/ai/services/idiom-dictionary.service';
import { EntryTagResponseDto, EntryTagResult } from '../src/modules/ai/dto/classify-symptom.dto';
import { findBannedVocabulary } from './banned-vocabulary';

interface TestCase {
  id: string;
  text: string;
  expectedVertical: 'physical' | 'emotional';
  expectedSystem?: string;
  expectedBodyAreaOrMood?: string;
  expectedUrgency?: number;
  expectedEmergency?: boolean;
  expectedOffTopic?: boolean;
  category: string;
  safetyRationale?: string;
  clinicalRationale?: string;
}

interface CaseEvaluation {
  id: string;
  text: string;
  category: string;
  result: EntryTagResult | EntryTagResponseDto;
  safetyAudit: {
    verticalMatch: boolean;
    areaMatch: boolean;
    bannedVocabularyFound: string[];
    noClinicalOutputs: boolean;
    safetyApproved: boolean;
  };
  aiReviewerAudit: {
    schemaValid: boolean;
    latencyOk: boolean;
    flaggedIssues: string[];
    calibrationRecommendation?: string;
  };
}

const checkBannedVocabulary = findBannedVocabulary;

async function runMultiAgentBattery() {
  console.log('\n===============================================================');
  console.log('  DUALISCHECKUP - MULTI-AGENT WELLNESS & SAFETY BATTERY        ');
  console.log('===============================================================\n');

  const rootDir = path.resolve(__dirname, '../../');
  const testCasesPath = path.resolve(rootDir, '.agents/agents/doctor/clinical_test_cases.json');

  if (!fs.existsSync(testCasesPath)) {
    throw new Error(`Safety test cases file not found at: ${testCasesPath}`);
  }

  const testCases: TestCase[] = JSON.parse(fs.readFileSync(testCasesPath, 'utf-8'));
  console.log(`[ORCHESTRATOR] Initialized. Loaded ${testCases.length} safety test cases from Safety Content Agent.`);

  // 1. Initialize AI Tagging Engine
  const idiomDict = new IdiomDictionaryService();
  const taggingService = new AiTaggingService(undefined, idiomDict);

  console.log('[ORCHESTRATOR] AI Tagging Engine initialized. Running Safety Content & AI Review evaluations...\n');

  const evaluations: CaseEvaluation[] = [];
  let totalBannedViolations = 0;
  let taggingFailures = 0;
  let totalLatency = 0;

  for (const tc of testCases) {
    const startTime = performance.now();
    const result = await taggingService.tagWithMetadata({ text: tc.text });
    const latencyMs = Math.round(performance.now() - startTime);
    totalLatency += latencyMs;

    const expectedArea = tc.expectedBodyAreaOrMood ?? tc.expectedSystem;
    const verticalMatch = tc.expectedOffTopic
      ? result.isOffTopic === true || result.vertical === null
      : result.vertical === tc.expectedVertical;
    const areaMatch = tc.expectedOffTopic ? true : result.bodyAreaOrMood === expectedArea;
    if (!verticalMatch || !areaMatch) {
      taggingFailures++;
    }

    // Safety checks: no clinical outputs in response and 0 banned vocabulary in layTerm
    const bannedFoundInLayTerm = checkBannedVocabulary(result.layTerm);
    if (bannedFoundInLayTerm.length > 0) {
      totalBannedViolations += bannedFoundInLayTerm.length;
    }

    const noClinicalOutputs =
      (result as any).urgencyScore === undefined &&
      (result as any).clinicalConcept === undefined &&
      (result as any).isEmergencyCandidate === undefined;

    const safetyApproved = verticalMatch && areaMatch && bannedFoundInLayTerm.length === 0 && noClinicalOutputs;

    // --- AI REVIEWER AGENT AUDIT ---
    const flaggedIssues: string[] = [];
    const schemaValid =
      typeof result.isOffTopic === 'boolean' &&
      (result.vertical === null || typeof result.vertical === 'string') &&
      (result.bodyAreaOrMood === null || typeof result.bodyAreaOrMood === 'string') &&
      (result.layTerm === null || typeof result.layTerm === 'string');

    if (!schemaValid) flaggedIssues.push('Schema validation failure');
    if (!verticalMatch && !tc.expectedOffTopic) flaggedIssues.push(`Vertical mismatch: got ${result.vertical}, expected ${tc.expectedVertical}`);
    if (!areaMatch && !tc.expectedOffTopic) flaggedIssues.push(`Area mismatch: got ${result.bodyAreaOrMood}, expected ${expectedArea}`);
    if (bannedFoundInLayTerm.length > 0) flaggedIssues.push(`Banned vocabulary detected in layTerm: ${bannedFoundInLayTerm.join(', ')}`);
    if (!noClinicalOutputs) flaggedIssues.push('Forbidden clinical outputs detected (urgencyScore/clinicalConcept)');

    let calibrationRecommendation: string | undefined;
    if (!areaMatch && !tc.expectedOffTopic) {
      calibrationRecommendation = `Add regex pattern to IdiomDictionaryService for: "${tc.text.substring(0, 30)}..." -> area: ${expectedArea}`;
    }

    evaluations.push({
      id: tc.id,
      text: tc.text,
      category: tc.category,
      result,
      safetyAudit: {
        verticalMatch,
        areaMatch,
        bannedVocabularyFound: bannedFoundInLayTerm,
        noClinicalOutputs,
        safetyApproved,
      },
      aiReviewerAudit: {
        schemaValid,
        latencyOk: latencyMs < 2000,
        flaggedIssues,
        calibrationRecommendation,
      },
    });
  }

  // --- PRINT SAFETY CONTENT & TAGGING SUMMARY ---
  console.log('---------------------------------------------------------------');
  console.log(' [1/3] SAFETY CONTENT & AI TAGGING AUDIT RESULTS');
  console.log('---------------------------------------------------------------');
  evaluations.forEach((e) => {
    const statusIcon = e.safetyAudit.safetyApproved ? '✅ PASS' : '❌ FAIL';
    console.log(`${statusIcon} [${e.id}] ${e.category}`);
    console.log(`    Input:    "${e.text}"`);
    console.log(`    Tags:     ${e.result.vertical ?? 'null'} / ${e.result.bodyAreaOrMood ?? 'null'}`);
    console.log(`    LayTerm:  "${e.result.layTerm ?? ''}"`);
    console.log(`    Source:   ${(e.result as EntryTagResult).source ?? 'dictionary'} (${(e.result as EntryTagResult).latencyMs ?? 0}ms)`);
    if (e.aiReviewerAudit.flaggedIssues.length > 0) {
      console.log(`    Issues:   ⚠️ ${e.aiReviewerAudit.flaggedIssues.join('; ')}`);
    }
    if (e.aiReviewerAudit.calibrationRecommendation) {
      console.log(`    Calib:    💡 ${e.aiReviewerAudit.calibrationRecommendation}`);
    }
    console.log('');
  });

  const safetyPassCount = evaluations.filter((e) => e.safetyAudit.safetyApproved).length;
  const safetyPassRate = ((safetyPassCount / evaluations.length) * 100).toFixed(1);
  const avgLatency = (totalLatency / evaluations.length).toFixed(1);

  console.log(`[SAFETY AUDITOR] Vocabulario vetado = 0: ${totalBannedViolations === 0 ? '✅ 0 infracciones' : `❌ ${totalBannedViolations} violaciones`}`);
  console.log(`[AI REVIEWER]    Calidad de etiquetado: ${evaluations.length - taggingFailures}/${evaluations.length} | Latencia: ${avgLatency}ms`);

  // --- 2. BACKEND AGENT TESTS ---
  console.log('\n---------------------------------------------------------------');
  console.log(' [2/3] BACKEND AGENT: RUNNING NESTJS UNIT & INTEGRATION TESTS');
  console.log('---------------------------------------------------------------');
  let backendPass = false;
  let backendOutput = '';
  try {
    const backendTestRun = execSync('npm test', {
      cwd: path.resolve(rootDir, 'backend'),
      encoding: 'utf-8',
    });
    backendPass = true;
    backendOutput = backendTestRun;
    console.log('✅ Backend unit tests passed cleanly (Vitest).');
  } catch (err: any) {
    backendPass = false;
    backendOutput = err.stdout || err.message;
    console.error('❌ Backend tests failed!');
  }

  // --- 3a. MEASURED SAFETY/VOCABULARY CHECKS (real tests, no fixed numbers) ---
  const runFlutterTest = (file: string): boolean => {
    try {
      execSync(`flutter test ${file}`, { cwd: path.resolve(rootDir, 'mobile'), encoding: 'utf-8', stdio: 'pipe' });
      return true;
    } catch {
      return false;
    }
  };
  const helpResourcesPass = runFlutterTest('test/shared/widgets/urgent_help_button_test.dart');
  const uiVocabularyPass = runFlutterTest('test/wellness_vocabulary_test.dart');
  console.log(`[SAFETY AUDITOR] Recursos de ayuda a ≤1 toque (urgent_help_button_test): ${helpResourcesPass ? 'OK' : 'FALLA'}`);
  console.log(`[SAFETY AUDITOR] Vocabulario vetado en la app (wellness_vocabulary_test): ${uiVocabularyPass ? 'OK' : 'FALLA'}`);

  // --- 3. FRONTEND AGENT TESTS ---
  console.log('\n---------------------------------------------------------------');
  console.log(' [3/3] FRONTEND AGENT: RUNNING FLUTTER WIDGET & UNIT TESTS');
  console.log('---------------------------------------------------------------');
  let frontendPass = false;
  let frontendOutput = '';
  try {
    const frontendTestRun = execSync('flutter test', {
      cwd: path.resolve(rootDir, 'mobile'),
      encoding: 'utf-8',
    });
    frontendPass = true;
    frontendOutput = frontendTestRun;
    console.log('✅ Frontend Flutter tests passed cleanly.');
  } catch (err: any) {
    frontendPass = false;
    frontendOutput = err.stdout || err.message;
    console.error('❌ Frontend Flutter tests failed!');
  }

  const backendCounts = /Tests\s+(\d+)\s+passed(?:\s*\((\d+)\))?/.exec(backendOutput);
  const backendSummary = backendCounts
    ? `${backendCounts[1]}/${backendCounts[2] ?? backendCounts[1]} pasadas`
    : backendPass ? 'Pasadas' : 'Fallidas';
  const frontendCounts = /\+(\d+)(?:\s+-(\d+))?:\s+(?:All tests passed|Some tests failed)/.exec(frontendOutput);
  const frontendSummary = frontendCounts
    ? `${frontendCounts[1]} pasadas${frontendCounts[2] ? `, ${frontendCounts[2]} fallidas` : ''}`
    : frontendPass ? 'Pasadas' : 'Fallidas';
  // No content flags (mentionsSelfHarm removed, strategy §18): any extra key is a violation.
  // Checked on the public response (internal metadata such as source/latencyMs is not sent).
  const allowedTagKeys = new Set(['isOffTopic', 'vertical', 'bodyAreaOrMood', 'layTerm']);
  const extraKeys = (r: EntryTagResult | EntryTagResponseDto) =>
    Object.keys(toPublicTags(r as EntryTagResult)).filter((k) => !allowedTagKeys.has(k));
  const contractViolations = evaluations.filter((e) => extraKeys(e.result).length > 0).length;
  const ok = (v: boolean) => (v ? '*Aprobado.*' : '*Requiere atención.*');

  // --- 4. ORCHESTRATOR REPORT COMPILATION ---
  console.log('\n===============================================================');
  console.log('  ORCHESTRATOR SUMMARY & CONSOLIDATED REPORT                   ');
  console.log('===============================================================');
  const reportData = {
    timestamp: new Date().toISOString(),
    orchestrator: 'orchestrator_agent',
    metrics: {
      bannedVocabularyViolationsInAiOutput: totalBannedViolations,
      uiVocabularyTestPassed: uiVocabularyPass,
      helpResourcesTestPassed: helpResourcesPass,
      aiContractViolations: contractViolations,
      taggingQualityRate: `${safetyPassRate}%`,
      averageLatencyMs: Number(avgLatency),
      backendTestsPassed: backendPass,
      frontendTestsPassed: frontendPass,
      overallStatus:
        totalBannedViolations === 0 && contractViolations === 0 &&
        helpResourcesPass && uiVocabularyPass && backendPass && frontendPass
          ? 'PASSED'
          : 'ACTION_REQUIRED',
    },
    evaluations,
  };

  const reportJsonPath = path.resolve(rootDir, '.agents/agents/agent-battery-report.json');
  fs.writeFileSync(reportJsonPath, JSON.stringify(reportData, null, 2), 'utf-8');

  // Generate Markdown report
  const markdownReport = `# Reporte Ejecutivo de Batería de Pruebas Multi-Agente

**Fecha y Hora:** ${reportData.timestamp}  
**Orquestador:** ${reportData.orchestrator}  
**Estado General:** **${reportData.metrics.overallStatus === 'PASSED' ? '✅ APROBADO' : '⚠️ ATENCIÓN REQUERIDA'}**

---

## 1. Métricas Consolidadas

| Métrica | Resultado | Meta | Estado |
|---|---|---|---|
| **Vocabulario vetado (salidas de IA)** | ${totalBannedViolations} infracciones | 0 | ${totalBannedViolations === 0 ? '✅ Cumplido' : '❌ Fallo'} |
| **Vocabulario vetado (textos de la app)** | wellness_vocabulary_test ${uiVocabularyPass ? 'OK' : 'falla'} | 0 | ${uiVocabularyPass ? '✅ Cumplido' : '❌ Fallo'} |
| **Recursos de ayuda a ≤1 toque** | urgent_help_button_test ${helpResourcesPass ? 'OK' : 'falla'} | pasa | ${helpResourcesPass ? '✅ Cumplido' : '❌ Fallo'} |
| **Campos fuera del contrato de IA** | ${contractViolations} | 0 | ${contractViolations === 0 ? '✅ Cumplido' : '❌ Fallo'} |
| **Calidad de Etiquetado de Diario** | ${evaluations.length - taggingFailures}/${evaluations.length} (${safetyPassRate}%) | ≥ 90% | ${Number(safetyPassRate) >= 90 ? '✅ Cumplido' : '⚠️ Revisar'} |
| **Latencia Promedio** | ${avgLatency} ms | < 2000 ms | ${Number(avgLatency) < 2000 ? '✅ Cumplido' : '❌ Fallo'} |
| **Pruebas Backend (Vitest)** | ${backendSummary} | 100% | ${backendPass ? '✅ Pasaron' : '❌ Fallaron'} |
| **Pruebas Frontend (Flutter)** | ${frontendSummary} | 100% | ${frontendPass ? '✅ Pasaron' : '❌ Fallaron'} |

---

## 2. Auditoría Detallada de Seguridad de Contenido y Etiquetado

| ID | Categoría | Entrada | Vertical | Área / Estado | Término Leigo | Salida Clínica | Estado de Seguridad |
|---|---|---|---|---|---|---|---|
${evaluations
  .map(
    (e) =>
      `| \`${e.id}\` | ${e.category} | "${e.text.substring(0, 35)}..." | ${e.result.vertical ?? 'null'} | \`${e.result.bodyAreaOrMood ?? 'null'}\` | "${e.result.layTerm ?? ''}" | ${extraKeys(e.result).join(', ') || 'Ninguna'} | ${e.safetyAudit.safetyApproved ? '✅ Aprobado' : '❌ Discrepancia'} |`
  )
  .join('\n')}

---

## 3. Calibraciones y Recomendaciones del Revisor de IA
${
  evaluations.filter((e) => e.aiReviewerAudit.calibrationRecommendation).length > 0
    ? evaluations
        .filter((e) => e.aiReviewerAudit.calibrationRecommendation)
        .map((e) => `- **[${e.id}]**: ${e.aiReviewerAudit.calibrationRecommendation}`)
        .join('\n')
    : '- *No se detectaron discrepancias que requieran calibración inmediata. Todas las áreas y expresiones clave fueron mapeadas con éxito.*'
}

---

## 4. Dictamen de los Agentes
- **Agente Auditor de Seguridad de Contenido**: ${ok(helpResourcesPass && uiVocabularyPass && totalBannedViolations === 0)} Recursos de ayuda: ${helpResourcesPass ? 'test OK' : 'test falla'}; vocabulario vetado en IA: ${totalBannedViolations}; en la app: ${uiVocabularyPass ? 'test OK' : 'test falla'}; la app no reacciona al contenido de lo escrito.
- **Agente Revisor de IA**: ${ok(contractViolations === 0 && taggingFailures === 0)} Campos fuera de contrato: ${contractViolations}; etiquetado correcto: ${evaluations.length - taggingFailures}/${evaluations.length}; latencia media ${avgLatency} ms.
- **Agente Backend**: ${ok(backendPass)} ${backendSummary}.
- **Agente Frontend**: ${ok(frontendPass)} ${frontendSummary}.
`;

  const reportMdPath = path.resolve(rootDir, '.agents/agents/agent-battery-report.md');
  fs.writeFileSync(reportMdPath, markdownReport, 'utf-8');

  console.log(`[ORCHESTRATOR] Reports successfully generated:`);
  console.log(`  - JSON:     ${reportJsonPath}`);
  console.log(`  - Markdown: ${reportMdPath}`);
  console.log(`\nOVERALL STATUS: ${reportData.metrics.overallStatus}\n`);
}

runMultiAgentBattery().catch((err) => {
  console.error('[ORCHESTRATOR] Fatal error running multi-agent battery:', err);
  process.exit(1);
});
