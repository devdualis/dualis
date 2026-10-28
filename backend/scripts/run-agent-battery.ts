import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';
import { findBannedVocabulary } from './banned-vocabulary';

interface TestCase {
  id: string;
  text: string;
  category: string;
  safetyRationale?: string;
  clinicalRationale?: string;
}

interface CaseEvaluation {
  id: string;
  text: string;
  category: string;
  bannedVocabularyFound: string[];
  safetyApproved: boolean;
}

const EXEC_BUFFER = 50 * 1024 * 1024;

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

  // --- 1. SAFETY CONTENT & BANNED VOCABULARY AUDIT ---
  console.log('\n---------------------------------------------------------------');
  console.log(' [1/4] SAFETY CONTENT AGENT: BANNED VOCABULARY & CONTRACT CHECK');
  console.log('---------------------------------------------------------------');

  const evaluations: CaseEvaluation[] = [];
  let totalBannedViolations = 0;

  for (const tc of testCases) {
    const bannedInText = findBannedVocabulary(tc.text);
    if (bannedInText.length > 0) {
      totalBannedViolations += bannedInText.length;
    }

    evaluations.push({
      id: tc.id,
      text: tc.text,
      category: tc.category,
      bannedVocabularyFound: bannedInText,
      safetyApproved: bannedInText.length === 0,
    });
  }

  console.log(`[SAFETY AUDITOR] Checked ${testCases.length} test cases for banned vocabulary.`);
  console.log(`[SAFETY AUDITOR] Banned vocabulary violations in test cases: ${totalBannedViolations}`);

  // --- 1b. JOURNAL V2 CONTRACT TESTS (Contract & Anti-AI Tagging Guardrails) ---
  let journalContractPass = false;
  let journalContractOutput = '';
  try {
    journalContractOutput = execSync('npx vitest run test/unit/journal-contract.spec.ts', {
      cwd: path.resolve(rootDir, 'backend'),
      encoding: 'utf-8',
      maxBuffer: EXEC_BUFFER,
    });
    journalContractPass = true;
    console.log('✅ Journal v2 contract & no-AI-tagging tests passed cleanly.');
  } catch (err: any) {
    journalContractPass = false;
    journalContractOutput = err.stdout || err.message;
    console.error('❌ Journal v2 contract tests failed!');
  }

  // --- 2. BACKEND AGENT TESTS ---
  console.log('\n---------------------------------------------------------------');
  console.log(' [2/4] BACKEND AGENT: RUNNING ALL UNIT & CONTRACT TESTS');
  console.log('---------------------------------------------------------------');
  let backendPass = false;
  let backendOutput = '';
  try {
    backendOutput = execSync('npm test', {
      cwd: path.resolve(rootDir, 'backend'),
      encoding: 'utf-8',
      maxBuffer: EXEC_BUFFER,
    });
    backendPass = true;
    console.log('✅ Backend unit and contract tests passed cleanly.');
  } catch (err: any) {
    backendPass = false;
    backendOutput = err.stdout || err.message;
    console.error('❌ Backend tests failed!');
  }

  // --- 3. SAFETY/VOCABULARY FLUTTER CHECKS (Help reachability & UI vocabulary) ---
  console.log('\n---------------------------------------------------------------');
  console.log(' [3/4] SAFETY AUDITOR: FLUTTER REACHABILITY & VOCABULARY');
  console.log('---------------------------------------------------------------');
  const runFlutterTest = (file: string): boolean => {
    try {
      execSync(`flutter test ${file}`, {
        cwd: path.resolve(rootDir, 'mobile'),
        encoding: 'utf-8',
        stdio: 'pipe',
        maxBuffer: EXEC_BUFFER,
      });
      return true;
    } catch {
      return false;
    }
  };
  const helpResourcesPass = runFlutterTest('test/shared/widgets/urgent_help_button_test.dart');
  const uiVocabularyPass = runFlutterTest('test/wellness_vocabulary_test.dart');
  console.log(`[SAFETY AUDITOR] Recursos de ayuda a ≤1 toque (urgent_help_button_test): ${helpResourcesPass ? 'OK' : 'FALLA'}`);
  console.log(`[SAFETY AUDITOR] Vocabulario vetado en la app (wellness_vocabulary_test): ${uiVocabularyPass ? 'OK' : 'FALLA'}`);

  // --- 4. FRONTEND AGENT TESTS ---
  console.log('\n---------------------------------------------------------------');
  console.log(' [4/4] FRONTEND AGENT: RUNNING FLUTTER WIDGET & UNIT TESTS');
  console.log('---------------------------------------------------------------');
  let frontendPass = false;
  let frontendOutput = '';
  try {
    const frontendTestRun = execSync('flutter test', {
      cwd: path.resolve(rootDir, 'mobile'),
      encoding: 'utf-8',
      maxBuffer: EXEC_BUFFER,
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
  const ok = (v: boolean) => (v ? '*Aprobado.*' : '*Requiere atención.*');

  // --- 5. ORCHESTRATOR REPORT COMPILATION ---
  console.log('\n===============================================================');
  console.log('  ORCHESTRATOR SUMMARY & CONSOLIDATED REPORT                   ');
  console.log('===============================================================');
  const reportData = {
    timestamp: new Date().toISOString(),
    orchestrator: 'orchestrator_agent',
    metrics: {
      bannedVocabularyViolationsInCases: totalBannedViolations,
      uiVocabularyTestPassed: uiVocabularyPass,
      helpResourcesTestPassed: helpResourcesPass,
      journalContractTestsPassed: journalContractPass,
      backendTestsPassed: backendPass,
      frontendTestsPassed: frontendPass,
      overallStatus:
        totalBannedViolations === 0 &&
        journalContractPass &&
        helpResourcesPass &&
        uiVocabularyPass &&
        backendPass &&
        frontendPass
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
| **Vocabulario vetado (casos de prueba)** | ${totalBannedViolations} infracciones | 0 | ${totalBannedViolations === 0 ? '✅ Cumplido' : '❌ Fallo'} |
| **Vocabulario vetado (textos de la app)** | wellness_vocabulary_test ${uiVocabularyPass ? 'OK' : 'falla'} | 0 | ${uiVocabularyPass ? '✅ Cumplido' : '❌ Fallo'} |
| **Recursos de ayuda a ≤1 toque** | urgent_help_button_test ${helpResourcesPass ? 'OK' : 'falla'} | pasa | ${helpResourcesPass ? '✅ Cumplido' : '❌ Fallo'} |
| **Contrato de Diario v2 (sin IA, marcadores, días locales)** | journal-contract.spec.ts ${journalContractPass ? 'OK' : 'falla'} | pasa | ${journalContractPass ? '✅ Cumplido' : '❌ Fallo'} |
| **Pruebas Backend (Vitest)** | ${backendSummary} | 100% | ${backendPass ? '✅ Pasaron' : '❌ Fallaron'} |
| **Pruebas Frontend (Flutter)** | ${frontendSummary} | 100% | ${frontendPass ? '✅ Pasaron' : '❌ Fallaron'} |

---

## 2. Auditoría Detallada de Seguridad de Contenido

| ID | Categoría | Entrada | Vocabulario Vetado | Estado de Seguridad |
|---|---|---|---|---|
${evaluations
  .map(
    (e) =>
      `| \`${e.id}\` | ${e.category} | "${e.text.substring(0, 45)}..." | ${e.bannedVocabularyFound.join(', ') || 'Ninguno'} | ${e.safetyApproved ? '✅ Aprobado' : '❌ Infracción'} |`
  )
  .join('\n')}

---

## 3. Dictamen de los Agentes
- **Agente Auditor de Seguridad de Contenido**: ${ok(helpResourcesPass && uiVocabularyPass && totalBannedViolations === 0)} Recursos de ayuda: ${helpResourcesPass ? 'test OK' : 'test falla'}; vocabulario vetado en casos: ${totalBannedViolations}; en la app: ${uiVocabularyPass ? 'test OK' : 'test falla'}; la app no reacciona al contenido de lo escrito.
- **Agente Revisor de Contrato**: ${ok(journalContractPass)} Contrato de diario verificado: sin rutas de IA, sin evaluación de severidad, marcadores conformes y conteos por días locales.
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
