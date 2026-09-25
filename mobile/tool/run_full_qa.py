import time
import json
import os
from qa_runner import QARunner

def run_qa():
    qa = QARunner()
    print("==================================================")
    print("🚀 STARTING COMPLETE DUALISCHECKUP QA WALKTHROUGH")
    print("==================================================")

    # -------------------------------------------------------------------------
    # STAGE 1: HOME SCREEN
    # -------------------------------------------------------------------------
    print("\n--- STAGE 1: HOME SCREEN VERIFICATION ---")
    root = qa.dump_ui()
    qa.screenshot("home_screen_initial")

    # Verify key elements on Home
    settings_btn = qa.find_nodes(root, desc_regex="Configurações")
    if not settings_btn:
        qa.log_finding("Navigation", "Settings Button Missing", "Settings gear button not found in home header", "HIGH")
    else:
        print("✓ Settings button found")

    psico_card = qa.find_nodes(root, desc_regex="Psicoemocional")
    if psico_card:
        print("✓ Psicoemocional section found")

    phys_card = qa.find_nodes(root, desc_regex="Avaliação Física")
    if phys_card:
        print("✓ Avaliação Física section found")

    # -------------------------------------------------------------------------
    # STAGE 2: SETTINGS SCREEN & PROFILE EDITING
    # -------------------------------------------------------------------------
    print("\n--- STAGE 2: SETTINGS & PROFILE EDITING ---")
    if settings_btn:
        qa.tap_node(settings_btn[0], delay=1.5)
    else:
        qa.tap(1006, 137, delay=1.5)

    root = qa.dump_ui()
    qa.screenshot("settings_screen_main")

    # 2.1 Photo / Avatar Selection
    print("Testing Avatar & Photo Selection...")
    # Avatar is near top center, let's find user avatar or "Alterar Foto" / "Alterar Avatar"
    avatar_btn = qa.find_nodes(root, desc_regex="Alterar Avatar")
    if not avatar_btn:
        # Tap on the avatar circle directly around center top (x=540, y=360)
        qa.tap(540, 360, delay=1.0)
    else:
        qa.tap_node(avatar_btn[0], delay=1.0)

    root = qa.dump_ui()
    qa.screenshot("settings_photo_picker_sheet")

    # Look for "Avatares Clínicos" or presets
    presets_btn = qa.find_nodes(root, text_regex="Avatares Clínicos") or qa.find_nodes(root, desc_regex="Avatares Clínicos")
    if presets_btn:
        qa.tap_node(presets_btn[0], delay=1.5)
        root = qa.dump_ui()
        qa.screenshot("settings_avatar_presets_sheet")
        # Tap one of the avatar icons in the bottom sheet (e.g. at x=300, y=1800)
        qa.tap(360, 1850, delay=1.0)
        time.sleep(1.0)
    else:
        # Dismiss sheet if opened camera/gallery option
        qa.keyevent(4, delay=1.0) # Back to dismiss modal

    root = qa.dump_ui()
    qa.screenshot("settings_avatar_updated")

    # 2.2 Name editing
    print("Testing Name Input...")
    # Look for EditText field
    edit_texts = qa.find_nodes(root, class_name="android.widget.EditText")
    if edit_texts:
        name_field = edit_texts[0]
        qa.tap_node(name_field, delay=0.5)
        # Select all and replace or type
        qa.adb("shell", "input", "keyevent", "123") # MOVE_END
        qa.type_text(" QA-User")
        qa.keyevent(4, delay=0.5) # Hide keyboard
        qa.screenshot("settings_name_edited")

    # 2.3 Date of Birth Picker
    print("Testing Date of Birth Picker...")
    dob_field = qa.find_nodes(root, desc_regex=r"\d{2}/\d{2}/\d{4}|Selecione sua data")
    if dob_field:
        qa.tap_node(dob_field[0], delay=1.5)
        root = qa.dump_ui()
        qa.screenshot("settings_dob_datepicker")
        # Look for OK button on DatePickerDialog
        ok_btn = qa.find_nodes(root, text_regex="OK|CONFIRMAR")
        if ok_btn:
            qa.tap_node(ok_btn[0], delay=1.0)
        else:
            qa.keyevent(4, delay=1.0)
    else:
        # Try tapping dob container around y=850
        qa.tap(540, 850, delay=1.5)
        root = qa.dump_ui()
        qa.screenshot("settings_dob_datepicker")
        ok_btn = qa.find_nodes(root, text_regex="OK|CONFIRMAR")
        if ok_btn:
            qa.tap_node(ok_btn[0], delay=1.0)
        else:
            qa.keyevent(4, delay=1.0)

    # 2.4 Save Profile
    print("Testing Save Profile Button...")
    root = qa.dump_ui()
    save_btn = qa.find_nodes(root, desc_regex="Salvar Perfil") or qa.find_nodes(root, text_regex="Salvar Perfil")
    if save_btn:
        qa.tap_node(save_btn[0], delay=2.0)
        qa.screenshot("settings_profile_saved")
    else:
        qa.log_finding("Settings", "Save Profile Button Missing", "Could not locate Salvar Perfil button", "MEDIUM")

    # 2.5 Security / Change Password
    print("Testing Security & Change Password Section...")
    qa.swipe(540, 1800, 540, 600, duration=400, delay=1.0)
    root = qa.dump_ui()
    qa.screenshot("settings_security_section")

    edit_texts = qa.find_nodes(root, class_name="android.widget.EditText")
    print(f"Found {len(edit_texts)} password edit fields")
    if len(edit_texts) >= 3:
        # Enter current password
        qa.tap_node(edit_texts[0], delay=0.5)
        qa.type_text("SenhaAtual123!")
        # Enter new password
        qa.tap_node(edit_texts[1], delay=0.5)
        qa.type_text("NovaSenha123!")
        # Enter mismatched confirm password
        qa.tap_node(edit_texts[2], delay=0.5)
        qa.type_text("Mismatch123!")
        qa.keyevent(4, delay=0.5) # Hide keyboard

        qa.screenshot("settings_password_mismatch_input")

        # Click "Alterar Senha"
        chg_pwd_btn = qa.find_nodes(root, desc_regex="Alterar Senha") or qa.find_nodes(root, text_regex="Alterar Senha")
        if chg_pwd_btn:
            qa.tap_node(chg_pwd_btn[0], delay=1.5)
            root = qa.dump_ui()
            qa.screenshot("settings_password_mismatch_error")

            # Check if error message displayed
            mismatch_err = qa.find_nodes(root, desc_regex="não coincidem") or qa.find_nodes(root, text_regex="não coincidem")
            if mismatch_err:
                print("✓ Password mismatch validation working as expected")
            else:
                qa.log_finding("Validation", "Password Mismatch Message Missing", "No error shown for non-matching passwords", "HIGH")
    else:
        print("Note: Password fields not directly found, possibly scrolled past or styled as custom widgets")

    # 2.6 Language switching
    print("Testing Language Switching (PT -> ES -> EN -> PT)...")
    qa.swipe(540, 1800, 540, 600, duration=400, delay=1.0)
    root = qa.dump_ui()
    qa.screenshot("settings_language_section")

    # Click Spanish
    es_tile = qa.find_nodes(root, desc_regex="Español") or qa.find_nodes(root, text_regex="Español")
    if es_tile:
        qa.tap_node(es_tile[0], delay=1.5)
        qa.screenshot("settings_language_es_active")
        print("✓ Switched to Spanish")

    # Click English
    root = qa.dump_ui()
    en_tile = qa.find_nodes(root, desc_regex="English") or qa.find_nodes(root, text_regex="English")
    if en_tile:
        qa.tap_node(en_tile[0], delay=1.5)
        qa.screenshot("settings_language_en_active")
        print("✓ Switched to English")

    # Click Portuguese back
    root = qa.dump_ui()
    pt_tile = qa.find_nodes(root, desc_regex="Português") or qa.find_nodes(root, text_regex="Português")
    if pt_tile:
        qa.tap_node(pt_tile[0], delay=1.5)
        qa.screenshot("settings_language_pt_restored")
        print("✓ Restored Portuguese")

    # 2.7 Privacy Center Navigation
    print("Testing Privacy Center Navigation from Settings...")
    qa.swipe(540, 1800, 540, 700, duration=400, delay=1.0)
    root = qa.dump_ui()
    privacy_tile = qa.find_nodes(root, desc_regex="Centro de Privacidade") or qa.find_nodes(root, text_regex="Centro de Privacidade")
    if privacy_tile:
        qa.tap_node(privacy_tile[0], delay=1.5)
        root = qa.dump_ui()
        qa.screenshot("privacy_center_screen")

        # Click Export Data
        export_btn = qa.find_nodes(root, desc_regex="Exportar Dados") or qa.find_nodes(root, text_regex="Exportar Dados")
        if export_btn:
            qa.tap_node(export_btn[0], delay=1.5)
            root = qa.dump_ui()
            qa.screenshot("privacy_export_data_modal")
            # Close modal
            close_btn = qa.find_nodes(root, text_regex="Fechar") or qa.find_nodes(root, desc_regex="Fechar")
            if close_btn:
                qa.tap_node(close_btn[0], delay=1.0)
            else:
                qa.keyevent(4, delay=1.0)

        # Click Delete Account
        root = qa.dump_ui()
        delete_btn = qa.find_nodes(root, desc_regex="Exclusão|Excluir") or qa.find_nodes(root, text_regex="Exclusão|Excluir")
        if delete_btn:
            qa.tap_node(delete_btn[0], delay=1.5)
            root = qa.dump_ui()
            qa.screenshot("privacy_delete_account_dialog")
            # Click Cancelar
            cancel_btn = qa.find_nodes(root, text_regex="Cancelar") or qa.find_nodes(root, desc_regex="Cancelar")
            if cancel_btn:
                qa.tap_node(cancel_btn[0], delay=1.0)
            else:
                qa.keyevent(4, delay=1.0)

        # Back to Settings
        qa.keyevent(4, delay=1.5)
    else:
        qa.log_finding("Settings", "Privacy Tile Missing", "Privacy Center tile not found in settings", "MEDIUM")

    # 2.8 Logout Dialog
    print("Testing Logout Dialog...")
    root = qa.dump_ui()
    logout_tile = qa.find_nodes(root, desc_regex="Sair|Encerrar") or qa.find_nodes(root, text_regex="Sair|Encerrar")
    if logout_tile:
        qa.tap_node(logout_tile[0], delay=1.5)
        root = qa.dump_ui()
        qa.screenshot("settings_logout_dialog")
        # Cancel logout to continue testing logged-in features
        cancel_btn = qa.find_nodes(root, text_regex="Cancelar") or qa.find_nodes(root, desc_regex="Cancelar")
        if cancel_btn:
            qa.tap_node(cancel_btn[0], delay=1.0)
        else:
            qa.keyevent(4, delay=1.0)

    # Return to Home
    qa.keyevent(4, delay=1.5)
    root = qa.dump_ui()
    qa.screenshot("home_screen_returned")

    # -------------------------------------------------------------------------
    # STAGE 3: HYDRATION DASHBOARD
    # -------------------------------------------------------------------------
    print("\n--- STAGE 3: HYDRATION DASHBOARD ---")
    # Bottom Nav Tab 4: Hydration (x=945, y=2258)
    qa.tap(945, 2258, delay=1.5)
    root = qa.dump_ui()
    qa.screenshot("hydration_dashboard_initial")

    # Click +250ml water button
    add_water_btn = qa.find_nodes(root, desc_regex=r"\+250|\+ 250|Adicionar Água") or qa.find_nodes(root, text_regex=r"\+250|\+ 250")
    if add_water_btn:
        print("Tapping +250ml water button...")
        qa.tap_node(add_water_btn[0], delay=1.5)
        root = qa.dump_ui()
        qa.screenshot("hydration_water_added_250ml")
    else:
        # Tap center area of quick add if any
        qa.tap(540, 1600, delay=1.5)
        root = qa.dump_ui()
        qa.screenshot("hydration_water_added_tap")

    # -------------------------------------------------------------------------
    # STAGE 4: HISTORY & 2D ANATOMICAL BODY MAP
    # -------------------------------------------------------------------------
    print("\n--- STAGE 4: HISTORY & ANATOMICAL BODY MAP ---")
    # Bottom Nav Tab 3: History (x=675, y=2258)
    qa.tap(675, 2258, delay=2.0)
    root = qa.dump_ui()
    qa.screenshot("history_dashboard_initial")

    # Tap on body map zones (Head ~ y=700, Chest ~ y=950, Abdomen ~ y=1150)
    print("Tapping Head anatomical zone...")
    qa.tap(540, 750, delay=1.5)
    root = qa.dump_ui()
    qa.screenshot("history_bodymap_head_selected")

    print("Tapping Chest anatomical zone...")
    qa.tap(540, 950, delay=1.5)
    root = qa.dump_ui()
    qa.screenshot("history_bodymap_chest_selected")

    # Scroll down to retrospective list
    qa.swipe(540, 1800, 540, 600, duration=400, delay=1.0)
    root = qa.dump_ui()
    qa.screenshot("history_retrospective_list")

    # -------------------------------------------------------------------------
    # STAGE 5: RESULTADO DO DIA (OUTCOME TAB)
    # -------------------------------------------------------------------------
    print("\n--- STAGE 5: RESULTADO DO DIA (OUTCOME TAB) ---")
    # Bottom Nav Tab 2: Outcome (x=405, y=2258)
    qa.tap(405, 2258, delay=2.0)
    root = qa.dump_ui()
    qa.screenshot("outcome_tab_view")

    # Look for recommended article card
    article_card = qa.find_nodes(root, desc_regex="Artigo|Leitura|Minutos")
    if article_card:
        qa.tap_node(article_card[0], delay=1.5)
        root = qa.dump_ui()
        qa.screenshot("outcome_article_detail_modal")
        qa.keyevent(4, delay=1.0) # dismiss modal/screen
    else:
        # Tap around article region
        qa.tap(540, 1750, delay=1.5)
        root = qa.dump_ui()
        qa.screenshot("outcome_article_detail_modal")
        qa.keyevent(4, delay=1.0)

    # -------------------------------------------------------------------------
    # STAGE 6: PHYSICAL TRIAGE WIZARD
    # -------------------------------------------------------------------------
    print("\n--- STAGE 6: PHYSICAL TRIAGE WIZARD ---")
    # Return to Home Tab 1 (x=135, y=2258)
    qa.tap(135, 2258, delay=1.5)
    root = qa.dump_ui()

    phys_btn = qa.find_nodes(root, desc_regex="Iniciar Avaliação Física")
    if phys_btn:
        qa.tap_node(phys_btn[0], delay=2.0)
    else:
        qa.tap(540, 1740, delay=2.0)

    root = qa.dump_ui()
    qa.screenshot("triage_phys_step1_systems")

    # Step 1: Select "Membros Superiores" or "Cabeça e Pescoço"
    membros_btn = qa.find_nodes(root, desc_regex="Membros Superiores") or qa.find_nodes(root, text_regex="Membros Superiores")
    if membros_btn:
        qa.tap_node(membros_btn[0], delay=1.0)
    else:
        # Tap first option around y=750
        qa.tap(540, 750, delay=1.0)

    # Click "Próximo"
    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=1.5)
    else:
        qa.tap(540, 2100, delay=1.5)

    # Step 2: Duration
    root = qa.dump_ui()
    qa.screenshot("triage_phys_step2_duration")
    dur_btn = qa.find_nodes(root, desc_regex="Começou agora|alguns dias")
    if dur_btn:
        qa.tap_node(dur_btn[0], delay=1.0)
    else:
        qa.tap(540, 800, delay=1.0)

    # Click "Próximo"
    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=1.5)
    else:
        qa.tap(540, 2100, delay=1.5)

    # Step 3: Specific trigger / limbs detail
    root = qa.dump_ui()
    qa.screenshot("triage_phys_step3_triggers")
    limb_btn = qa.find_nodes(root, desc_regex="Ombro|Braço|Cotovelo|Mão|Esforço")
    if limb_btn:
        qa.tap_node(limb_btn[0], delay=1.0)
    else:
        qa.tap(540, 850, delay=1.0)

    # Click "Próximo"
    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=1.5)
    else:
        qa.tap(540, 2100, delay=1.5)

    # Step 4: Intensity
    root = qa.dump_ui()
    qa.screenshot("triage_phys_step4_intensity")
    # Select intensity 3 (safe, non-emergency)
    intensity_3 = qa.find_nodes(root, text_regex="^3$") or qa.find_nodes(root, desc_regex="^3$")
    if intensity_3:
        qa.tap_node(intensity_3[0], delay=1.0)
    else:
        qa.tap(540, 1100, delay=1.0)

    # Click "Próximo"
    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=1.5)
    else:
        qa.tap(540, 2100, delay=1.5)

    # Step 5: Preview & Optional Narrative
    root = qa.dump_ui()
    qa.screenshot("triage_phys_step5_preview_narrative")

    # Enter narrative in optional textfield
    narrative_field = qa.find_nodes(root, class_name="android.widget.EditText")
    if narrative_field:
        qa.tap_node(narrative_field[0], delay=0.5)
        qa.type_text("Dor leve no ombro apos treino")
        qa.keyevent(4, delay=0.5) # hide keyboard
        qa.screenshot("triage_phys_narrative_entered")

    # Click "Confirmar e Finalizar"
    finish_btn = qa.find_nodes(root, desc_regex="Confirmar|Finalizar") or qa.find_nodes(root, text_regex="Confirmar|Finalizar")
    if finish_btn:
        qa.tap_node(finish_btn[0], delay=3.0)
    else:
        qa.tap(540, 2100, delay=3.0)

    root = qa.dump_ui()
    qa.screenshot("home_after_physical_triage")

    # -------------------------------------------------------------------------
    # STAGE 7: PSICOEMOCIONAL TRIAGE WIZARD
    # -------------------------------------------------------------------------
    print("\n--- STAGE 7: PSICOEMOCIONAL TRIAGE WIZARD ---")
    update_psico = qa.find_nodes(root, desc_regex="Atualizar")
    if update_psico:
        qa.tap_node(update_psico[0], delay=2.0)
    else:
        qa.tap(790, 1300, delay=2.0)

    root = qa.dump_ui()
    qa.screenshot("triage_emo_step1_dimensions")

    # Step 1: Select "Estresse / Burnout"
    stress_btn = qa.find_nodes(root, desc_regex="Estresse|Burnout") or qa.find_nodes(root, text_regex="Estresse|Burnout")
    if stress_btn:
        qa.tap_node(stress_btn[0], delay=1.0)
    else:
        qa.tap(540, 950, delay=1.0)

    # Next
    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=1.5)
    else:
        qa.tap(540, 2100, delay=1.5)

    # Step 2: Duration
    root = qa.dump_ui()
    qa.screenshot("triage_emo_step2_duration")
    dur_btn = qa.find_nodes(root, desc_regex="Começou hoje|alguns dias")
    if dur_btn:
        qa.tap_node(dur_btn[0], delay=1.0)
    else:
        qa.tap(540, 800, delay=1.0)

    # Next
    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=1.5)
    else:
        qa.tap(540, 2100, delay=1.5)

    # Step 3: Trigger
    root = qa.dump_ui()
    qa.screenshot("triage_emo_step3_triggers")
    trig_btn = qa.find_nodes(root, desc_regex="Trabalho|Cobrança|Prazos|Sobrecarga")
    if trig_btn:
        qa.tap_node(trig_btn[0], delay=1.0)
    else:
        qa.tap(540, 850, delay=1.0)

    # Next
    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=1.5)
    else:
        qa.tap(540, 2100, delay=1.5)

    # Step 4: Intensity
    root = qa.dump_ui()
    qa.screenshot("triage_emo_step4_intensity")
    # Select "Moderada"
    mod_btn = qa.find_nodes(root, desc_regex="Moderada") or qa.find_nodes(root, text_regex="Moderada")
    if mod_btn:
        qa.tap_node(mod_btn[0], delay=1.0)
    else:
        qa.tap(540, 1000, delay=1.0)

    # Next
    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=1.5)
    else:
        qa.tap(540, 2100, delay=1.5)

    # Step 5: Preview & Optional Narrative
    root = qa.dump_ui()
    qa.screenshot("triage_emo_step5_preview_narrative")

    finish_btn = qa.find_nodes(root, desc_regex="Confirmar|Finalizar") or qa.find_nodes(root, text_regex="Confirmar|Finalizar")
    if finish_btn:
        qa.tap_node(finish_btn[0], delay=3.0)
    else:
        qa.tap(540, 2100, delay=3.0)

    root = qa.dump_ui()
    qa.screenshot("home_after_both_triages_complete")

    # -------------------------------------------------------------------------
    # STAGE 8: EMERGENCY RED SCREEN & SAFETY TRIGGER
    # -------------------------------------------------------------------------
    print("\n--- STAGE 8: EMERGENCY RED SCREEN SAFETY NET ---")
    # Start physical triage again to trigger Level 5 emergency
    phys_btn = qa.find_nodes(root, desc_regex="Iniciar|Atualizar|Avaliação Física")
    if phys_btn:
        qa.tap_node(phys_btn[0], delay=2.0)
    else:
        qa.tap(540, 1740, delay=2.0)

    root = qa.dump_ui()
    # Step 1: Select Cardiovascular
    cardio_btn = qa.find_nodes(root, desc_regex="Cardiovascular") or qa.find_nodes(root, text_regex="Cardiovascular")
    if cardio_btn:
        qa.tap_node(cardio_btn[0], delay=1.0)
    else:
        qa.tap(540, 900, delay=1.0)

    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=1.5)
    else:
        qa.tap(540, 2100, delay=1.5)

    # Step 2: Duration
    root = qa.dump_ui()
    dur_btn = qa.find_nodes(root, desc_regex="Começou agora")
    if dur_btn:
        qa.tap_node(dur_btn[0], delay=1.0)
    else:
        qa.tap(540, 800, delay=1.0)

    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=1.5)
    else:
        qa.tap(540, 2100, delay=1.5)

    # Step 3: Trigger
    root = qa.dump_ui()
    trig_btn = qa.find_nodes(root, desc_regex="repouso|esforço")
    if trig_btn:
        qa.tap_node(trig_btn[0], delay=1.0)
    else:
        qa.tap(540, 850, delay=1.0)

    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=1.5)
    else:
        qa.tap(540, 2100, delay=1.5)

    # Step 4: SELECT INTENSITY 5 -> EMERGENCY TRIGGER!
    root = qa.dump_ui()
    print("Selecting Intensity 5 (Maximum / Critical)...")
    int_5 = qa.find_nodes(root, text_regex="^5$") or qa.find_nodes(root, desc_regex="^5$")
    if int_5:
        qa.tap_node(int_5[0], delay=1.0)
    else:
        qa.tap(950, 1100, delay=1.0)

    # In Step 4, selecting 5 should trigger emergency gate upon tap or next
    next_btn = qa.find_nodes(root, desc_regex="Próximo") or qa.find_nodes(root, text_regex="Próximo")
    if next_btn:
        qa.tap_node(next_btn[0], delay=2.0)
    else:
        qa.tap(540, 2100, delay=2.0)

    root = qa.dump_ui()
    qa.screenshot("emergency_red_screen_triggered")

    # Verify Emergency Screen elements: SAMU 192, 190, 188
    samu_btn = qa.find_nodes(root, desc_regex="192|SAMU") or qa.find_nodes(root, text_regex="192|SAMU")
    if samu_btn:
        print("✓ SAMU 192 button verified on Red Screen")
    else:
        qa.log_finding("Emergency", "SAMU 192 Button Missing", "SAMU emergency dialer button not found", "CRITICAL")

    # Safe dismiss from Emergency
    dismiss_btn = qa.find_nodes(root, desc_regex="Voltar|Segurança|Descartar") or qa.find_nodes(root, text_regex="Voltar|Segurança|Descartar")
    if dismiss_btn:
        qa.tap_node(dismiss_btn[0], delay=1.5)
    else:
        qa.keyevent(4, delay=1.5)

    root = qa.dump_ui()
    qa.screenshot("after_emergency_dismissal")

    print("\n==================================================")
    print("🎉 QA WALKTHROUGH COMPLETED!")
    print(f"Total findings: {len(qa.findings)}")
    for f in qa.findings:
        print(f" - [{f['severity']}] {f['title']}: {f['description']}")
    print("==================================================")

if __name__ == "__main__":
    run_qa()
