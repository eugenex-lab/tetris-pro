/**
 * Formats the Current Data table - PRESERVES existing MATURITY DATE and Status data
 */
function formatCurrentSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getActiveSheet();

  const NAVY = "#0b1b3e",
    OFF_WHITE = "#F5F3EC",
    WHITE = "#FFFFFF",
    TEXT_WHITE = "#FFFFFF",
    TEXT_DARK = "#1A1A1A";
  const INNER_CLR = "#8899aa",
    LIGHT_GRAY = "#f9f9f9",
    USD_COLOR = "#e8f4f8",
    LIGHT_COLD = "#e3f0f5";
  const startRow = 20,
    endRow = 700;

  // Month-end date
  const today = new Date();
  const end = new Date(today.getFullYear(), today.getMonth() + 1, 0);
  const formatFull = (d) =>
    Utilities.formatDate(d, Session.getScriptTimeZone(), "MMM d, yyyy");
  const endDateText = formatFull(end);

  // Save existing MATURITY DATE (Col K) and Status (Col L)
  const savedMaturityDates = [],
    savedStatuses = [];
  for (let row = startRow + 1; row <= endRow; row++) {
    savedMaturityDates.push(sheet.getRange(row, 11).getValue());
    savedStatuses.push(sheet.getRange(row, 12).getValue());
  }

  // Clear columns J-N
  sheet.getRange(`J${startRow}:N${endRow}`).clear();

  // =========================
  // FX RATE + HEADER
  // =========================

  if (!sheet.getRange("A2").getValue()) sheet.getRange("A2").setValue("");

  // A1
  sheet
    .getRange("A1")
    .setValue("FX RATE")
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold")
    .setHorizontalAlignment("center");

  // B1 → AUM Snapshot
  sheet
    .getRange("B1")
    .setValue("AUM Snapshot")
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold")
    .setHorizontalAlignment("center");

  // B2 → Month-end date
  sheet
    .getRange("B2")
    .setValue(endDateText)
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold")
    .setHorizontalAlignment("center");

  sheet
    .getRange("A2")
    .setBackground("#e6f0ff")
    .setFontColor(TEXT_DARK)
    .setFontWeight("bold")
    .setNumberFormat("#,##0.00")
    .setHorizontalAlignment("center")
    .setBorder(
      true,
      true,
      true,
      true,
      true,
      true,
      NAVY,
      SpreadsheetApp.BorderStyle.SOLID_MEDIUM,
    );

  // Total Portfolio COF
  sheet
    .getRange("A4:C4")
    .merge()
    .setValue("Total Portfolio COF")
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold")
    .setHorizontalAlignment("center");
  [
    ["", "AUM", "Weight"],
    ["Total NGN AUM", "", ""],
    ["Total USD AUM (USD)", "", ""],
    ["Total AUM", "", ""],
  ].forEach((r, i) => sheet.getRange(`A${5 + i}:C${5 + i}`).setValues([r]));
  sheet
    .getRange("A5:C5")
    .setBackground("#F2F2F2")
    .setFontWeight("bold")
    .setHorizontalAlignment("center")
    .setBorder(
      true,
      true,
      true,
      true,
      true,
      true,
      INNER_CLR,
      SpreadsheetApp.BorderStyle.SOLID,
    );
  sheet
    .getRange("A6:A8")
    .setBackground("#F2F2F2")
    .setFontWeight("bold")
    .setBorder(
      true,
      true,
      true,
      true,
      true,
      true,
      INNER_CLR,
      SpreadsheetApp.BorderStyle.SOLID,
    );
  sheet
    .getRange("B6")
    .setFormula(
      `=SUMIF(E${startRow + 1}:E${endRow},"NGN",G${startRow + 1}:G${endRow})`,
    )
    .setNumberFormat("#,##0.00");
  sheet
    .getRange("B7")
    .setFormula(
      `=SUMIF(E${startRow + 1}:E${endRow},"USD",G${startRow + 1}:G${endRow})`,
    )
    .setNumberFormat("#,##0.00");
  sheet
    .getRange("B8")
    .setFormula(`=B6+(B7*A2)`)
    .setNumberFormat("#,##0.00")
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold");
  sheet
    .getRange("C6")
    .setFormula("=B6/B8")
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("center");
  sheet
    .getRange("C7")
    .setFormula("=B7*A2/B8")
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("center");
  sheet.getRange("C8").clear();
  sheet
    .getRange("B6:C7")
    .setBorder(
      true,
      true,
      true,
      true,
      true,
      true,
      INNER_CLR,
      SpreadsheetApp.BorderStyle.SOLID,
    )
    .setBackground(WHITE);
  sheet
    .getRange("A8:C8")
    .setBorder(
      true,
      true,
      true,
      true,
      true,
      true,
      NAVY,
      SpreadsheetApp.BorderStyle.SOLID_MEDIUM,
    );

  // Total COF
  sheet.getRange("D5:D8").clear();
  sheet
    .getRange("D5")
    .setValue("Total COF")
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold")
    .setHorizontalAlignment("center");
  sheet
    .getRange("D6")
    .setFormula("=B16")
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("center");
  sheet
    .getRange("D7")
    .setFormula("=E16")
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("center");
  sheet
    .getRange("D8")
    .setFormula("=SUMPRODUCT(C6:C7,D6:D7)")
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("center");
  sheet
    .getRange("D5:D8")
    .setBorder(
      true,
      true,
      true,
      true,
      true,
      true,
      NAVY,
      SpreadsheetApp.BorderStyle.SOLID_MEDIUM,
    );

  // NGN COF
  sheet
    .getRange("A10:B10")
    .merge()
    .setValue("NGN COF")
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold")
    .setHorizontalAlignment("center");
  [
    "Autopay AUM",
    "Non-Autopay AUM",
    "Total NGN AUM",
    "Autopay COF (Effective Rate)",
    "Non-Autopay COF (Effective Rate)",
    "Total NGN COF (Effective Rate)",
  ].forEach((l, i) => sheet.getRange(`A${11 + i}`).setValue(l));
  sheet
    .getRange("B11")
    .setFormula(
      `=SUMIFS(G${startRow + 1}:G${endRow},E${startRow + 1}:E${endRow},"NGN",C${startRow + 1}:C${endRow},"YES")`,
    )
    .setNumberFormat("#,##0.00");
  sheet
    .getRange("B12")
    .setFormula(
      `=SUMIFS(G${startRow + 1}:G${endRow},E${startRow + 1}:E${endRow},"NGN",C${startRow + 1}:C${endRow},"NO")`,
    )
    .setNumberFormat("#,##0.00");
  sheet.getRange("B13").setFormula("=B6").setNumberFormat("#,##0.00");

  // ✅ FIXED B14: Convert text in column L to numbers using VALUE()
  sheet
    .getRange("B14")
    .setFormula(
      `=IFERROR(SUMPRODUCT(G${startRow + 1}:G${endRow},VALUE(L${startRow + 1}:L${endRow}),--(E${startRow + 1}:E${endRow}="NGN"),--(C${startRow + 1}:C${endRow}="YES"))/SUMIFS(G${startRow + 1}:G${endRow},E${startRow + 1}:E${endRow},"NGN",C${startRow + 1}:C${endRow},"YES"),0)`,
    )
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("right");

  // ✅ FIXED B15: Convert text in column L to numbers using VALUE()
  sheet
    .getRange("B15")
    .setFormula(
      `=IFERROR(SUMPRODUCT(G${startRow + 1}:G${endRow},VALUE(L${startRow + 1}:L${endRow}),--(E${startRow + 1}:E${endRow}="NGN"),--(C${startRow + 1}:C${endRow}="NO"))/SUMIFS(G${startRow + 1}:G${endRow},E${startRow + 1}:E${endRow},"NGN",C${startRow + 1}:C${endRow},"NO"),0)`,
    )
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("right");

  // ✅ FIXED B16: Also use VALUE() on column L for consistency
  sheet
    .getRange("B16")
    .setFormula(
      `=IFERROR(SUMPRODUCT(G${startRow + 1}:G${endRow},VALUE(L${startRow + 1}:L${endRow}),--(E${startRow + 1}:E${endRow}="NGN"))/SUMIF(E${startRow + 1}:E${endRow},"NGN",G${startRow + 1}:G${endRow}),0)`,
    )
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("right");

  sheet.getRange("A11:B12").setBackground(LIGHT_COLD);
  sheet.getRange("A14:B15").setBackground(LIGHT_COLD);
  for (let r = 11; r <= 16; r++) {
    if (![11, 12, 14, 15].includes(r))
      sheet.getRange(`A${r}:B${r}`).setBackground(WHITE);
    sheet
      .getRange(`A${r}`)
      .setFontWeight("bold")
      .setBorder(
        true,
        true,
        true,
        true,
        true,
        true,
        INNER_CLR,
        SpreadsheetApp.BorderStyle.SOLID,
      );
    sheet
      .getRange(`B${r}`)
      .setBorder(
        true,
        true,
        true,
        true,
        true,
        true,
        INNER_CLR,
        SpreadsheetApp.BorderStyle.SOLID,
      );
  }
  sheet
    .getRange("A13:B13")
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold")
    .setBorder(
      true,
      true,
      true,
      true,
      true,
      true,
      NAVY,
      SpreadsheetApp.BorderStyle.SOLID_MEDIUM,
    );
  sheet
    .getRange("A16:B16")
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold")
    .setBorder(
      true,
      true,
      true,
      true,
      true,
      true,
      NAVY,
      SpreadsheetApp.BorderStyle.SOLID_MEDIUM,
    );

  // USD COF
  sheet
    .getRange("D10:E10")
    .merge()
    .setValue("USD COF")
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold")
    .setHorizontalAlignment("center");
  [
    "Autopay AUM (USD)",
    "Non-Autopay AUM (USD)",
    "Total USD AUM",
    "Autopay COF (Effective Rate)",
    "Non-Autopay COF (Effective Rate)",
    "Total USD COF (Effective Rate)",
  ].forEach((l, i) => sheet.getRange(`D${11 + i}`).setValue(l));
  sheet
    .getRange("E11")
    .setFormula(
      `=SUMIFS(G${startRow + 1}:G${endRow},E${startRow + 1}:E${endRow},"USD",C${startRow + 1}:C${endRow},"YES")`,
    )
    .setNumberFormat("#,##0.00");
  sheet
    .getRange("E12")
    .setFormula(
      `=SUMIFS(G${startRow + 1}:G${endRow},E${startRow + 1}:E${endRow},"USD",C${startRow + 1}:C${endRow},"NO")`,
    )
    .setNumberFormat("#,##0.00");
  sheet.getRange("E13").setFormula("=B7").setNumberFormat("#,##0.00");

  // ✅ FIXED E14: Convert text in column L to numbers using VALUE()
  sheet
    .getRange("E14")
    .setFormula(
      `=IFERROR(SUMPRODUCT(G${startRow + 1}:G${endRow},VALUE(L${startRow + 1}:L${endRow}),--(E${startRow + 1}:E${endRow}="USD"),--(C${startRow + 1}:C${endRow}="YES"))/SUMIFS(G${startRow + 1}:G${endRow},E${startRow + 1}:E${endRow},"USD",C${startRow + 1}:C${endRow},"YES"),0)`,
    )
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("right");

  // ✅ FIXED E15: Convert text in column L to numbers using VALUE()
  sheet
    .getRange("E15")
    .setFormula(
      `=IFERROR(SUMPRODUCT(G${startRow + 1}:G${endRow},VALUE(L${startRow + 1}:L${endRow}),--(E${startRow + 1}:E${endRow}="USD"),--(C${startRow + 1}:C${endRow}="NO"))/SUMIFS(G${startRow + 1}:G${endRow},E${startRow + 1}:E${endRow},"USD",C${startRow + 1}:C${endRow}="NO"),0)`,
    )
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("right");

  // ✅ FIXED E16: Also use VALUE() on column L for consistency
  sheet
    .getRange("E16")
    .setFormula(
      `=IFERROR(SUMPRODUCT(G${startRow + 1}:G${endRow},VALUE(L${startRow + 1}:L${endRow}),--(E${startRow + 1}:E${endRow}="USD"))/SUMIF(E${startRow + 1}:E${endRow},"USD",G${startRow + 1}:G${endRow}),0)`,
    )
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("right");

  for (let r = 11; r <= 16; r++) {
    sheet
      .getRange(`D${r}`)
      .setBackground(USD_COLOR)
      .setFontWeight("bold")
      .setBorder(
        true,
        true,
        true,
        true,
        true,
        true,
        INNER_CLR,
        SpreadsheetApp.BorderStyle.SOLID,
      );
    sheet
      .getRange(`E${r}`)
      .setBorder(
        true,
        true,
        true,
        true,
        true,
        true,
        INNER_CLR,
        SpreadsheetApp.BorderStyle.SOLID,
      );
  }
  sheet
    .getRange("D13:E13")
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold")
    .setBorder(
      true,
      true,
      true,
      true,
      true,
      true,
      NAVY,
      SpreadsheetApp.BorderStyle.SOLID_MEDIUM,
    );
  sheet
    .getRange("D16:E16")
    .setBackground(NAVY)
    .setFontColor(TEXT_WHITE)
    .setFontWeight("bold")
    .setBorder(
      true,
      true,
      true,
      true,
      true,
      true,
      NAVY,
      SpreadsheetApp.BorderStyle.SOLID_MEDIUM,
    );

  // Headers Row 20
  [
    "ACCOUNT NAME",
    "START DATE",
    "AUTOPAY",
    "AUTOPAY PERIOD",
    "CURRENCY",
    "TENOR",
    "PRINCIPAL",
    "INTEREST RATE",
    "WHT CHECK",
    "Nominal Rate",
    "Compounding Freq.",
    "Eff. Int Rate",
    "MATURITY DATE",
    "Status",
  ].forEach((h, i) =>
    sheet
      .getRange(startRow, i + 1)
      .setValue(h)
      .setBackground(NAVY)
      .setFontColor(TEXT_WHITE)
      .setFontWeight("bold")
      .setHorizontalAlignment("center"),
  );

  // Add formulas & restore data
  for (let row = startRow + 1; row <= endRow; row++) {
    let idx = row - (startRow + 1);
    sheet
      .getRange(row, 10)
      .setFormula(`=IF(A${row}<>"",IF(I${row}="YES",H${row}*0.9,H${row}),"")`)
      .setNumberFormat("0.00%")
      .setHorizontalAlignment("right");
    sheet
      .getRange(row, 11)
      .setFormula(
        `=IF(A${row}<>"",IF(C${row}="YES",IF(AND(ISNUMBER(F${row}),ISNUMBER(D${row}),F${row}>0,D${row}>0),F${row}/D${row},""),1),"")`,
      )
      .setNumberFormat("#,##0")
      .setHorizontalAlignment("right");
    sheet
      .getRange(row, 12)
      .setFormula(
        `=IF(AND(A${row}<>"",ISNUMBER(J${row}),ISNUMBER(K${row}),K${row}>0),IF(J${row}=0,0,EFFECT(J${row},K${row})),IF(AND(A${row}<>"",J${row}=0),0,""))`,
      )
      .setNumberFormat("0.00%")
      .setHorizontalAlignment("right");
    if (savedMaturityDates[idx])
      sheet.getRange(row, 13).setValue(savedMaturityDates[idx]);
    if (savedStatuses[idx])
      sheet.getRange(row, 14).setValue(savedStatuses[idx]);
  }

  // Column widths
  [200, 150, 100, 200, 150, 70, 120, 100, 90, 150, 150, 220, 150, 100].forEach(
    (w, i) => sheet.setColumnWidth(i + 1, w),
  );

  // Row heights
  [1, 2, 4, 5, 8, 10, 20].forEach((r) =>
    sheet.setRowHeight(
      r,
      [35, 40, 35, 30, 35, 35, 40][[1, 2, 4, 5, 8, 10, 20].indexOf(r)],
    ),
  );
  for (let r = 11; r <= 16; r++) sheet.setRowHeight(r, 30);
  for (let r = startRow + 1; r <= endRow; r++) sheet.setRowHeight(r, 25);

  // Alternating row colors & COF column backgrounds
  for (let row = startRow + 1; row <= endRow; row++) {
    let bg = row % 2 === 0 ? OFF_WHITE : WHITE;
    sheet.getRange(row, 1, 1, 14).setBackground(bg).setFontColor(TEXT_DARK);
    sheet.getRange(row, 10, 1, 3).setBackground(LIGHT_GRAY);
  }

  // Number formats
  let dataRows = endRow - startRow;
  sheet
    .getRange(startRow + 1, 2, dataRows, 1)
    .setNumberFormat("dd-mmm-yyyy")
    .setHorizontalAlignment("center");
  sheet
    .getRange(startRow + 1, 13, dataRows, 1)
    .setNumberFormat("dd-mmm-yyyy")
    .setHorizontalAlignment("center");
  sheet
    .getRange(startRow + 1, 6, dataRows, 1)
    .setNumberFormat("#,##0")
    .setHorizontalAlignment("right");
  sheet
    .getRange(startRow + 1, 7, dataRows, 1)
    .setNumberFormat("#,##0.00")
    .setHorizontalAlignment("right");
  sheet
    .getRange(startRow + 1, 8, dataRows, 1)
    .setNumberFormat("0.00%")
    .setHorizontalAlignment("right");
  [3, 4, 5, 9, 14].forEach((c) =>
    sheet
      .getRange(startRow + 1, c, dataRows, 1)
      .setHorizontalAlignment("center"),
  );

  // Conditional formatting
  let whtRange = sheet.getRange(startRow + 1, 9, dataRows, 1);
  sheet.setConditionalFormatRules([
    SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo("YES")
      .setBackground("#C6EFCE")
      .setFontColor("#006100")
      .setRanges([whtRange])
      .build(),
    SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo("NO")
      .setBackground("#FFC7CE")
      .setFontColor("#9C0006")
      .setRanges([whtRange])
      .build(),
  ]);

  let statusRange = sheet.getRange(startRow + 1, 14, dataRows, 1);
  let rules = sheet.getConditionalFormatRules();
  rules.push(
    SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo("Current")
      .setBackground("#C6EFCE")
      .setFontColor("#006100")
      .setRanges([statusRange])
      .build(),
  );
  rules.push(
    SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo("Matured")
      .setBackground("#FFC7CE")
      .setFontColor("#9C0006")
      .setRanges([statusRange])
      .build(),
  );
  sheet.setConditionalFormatRules(rules);

  // Borders
  sheet
    .getRange(startRow, 1, endRow - startRow + 1, 14)
    .setBorder(
      true,
      true,
      true,
      true,
      null,
      null,
      NAVY,
      SpreadsheetApp.BorderStyle.SOLID_MEDIUM,
    )
    .setBorder(
      null,
      null,
      null,
      null,
      true,
      true,
      INNER_CLR,
      SpreadsheetApp.BorderStyle.SOLID,
    );

  sheet.autoResizeColumns(1, 14);
  SpreadsheetApp.getUi().alert("✅ Formatting complete!");
}

/**
 * Appends single-row Total Portfolio COF summary to "Total Portfolio COF" sheet
 */
function addSingleRowTotalPortfolioCOF() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const dataSheet = ss.getActiveSheet();
  const summarySheetName = "Total Portfolio COF";

  let summarySheet = ss.getSheetByName(summarySheetName);
  if (!summarySheet) summarySheet = ss.insertSheet(summarySheetName);

  let nextRow = summarySheet.getLastRow() + 1;

  const today = new Date();
  const end = new Date(today.getFullYear(), today.getMonth() + 1, 0);

  // Date format: 28-Feb-26
  const formatShort = (d) =>
    Utilities.formatDate(d, Session.getScriptTimeZone(), "dd-MMM-yy");

  // A & B empty
  summarySheet.getRange(nextRow, 1).setValue("");
  summarySheet.getRange(nextRow, 2).setValue("");

  // C → Date
  summarySheet.getRange(nextRow, 3).setValue(formatShort(end));

  // D → FX Rate (comma)
  summarySheet
    .getRange(nextRow, 4)
    .setValue(dataSheet.getRange("A2").getValue())
    .setNumberFormat("#,##0.00");

  // E → USD AUM (B7 * A2)
  summarySheet
    .getRange(nextRow, 5)
    .setFormula(`='${dataSheet.getName()}'!B7*'${dataSheet.getName()}'!A2`)
    .setNumberFormat("#,##0.00");

  // F → NGN AUM (B6)
  summarySheet
    .getRange(nextRow, 6)
    .setFormula(`='${dataSheet.getName()}'!B6`)
    .setNumberFormat("#,##0.00");

  // G → Total AUM
  summarySheet
    .getRange(nextRow, 7)
    .setFormula(`=E${nextRow}+F${nextRow}`)
    .setNumberFormat("#,##0.00");

  // H → from C7 (%)
  summarySheet
    .getRange(nextRow, 8)
    .setFormula(`='${dataSheet.getName()}'!C7`)
    .setNumberFormat("0.00%");

  // I → from C6 (%)
  summarySheet
    .getRange(nextRow, 9)
    .setFormula(`='${dataSheet.getName()}'!C6`)
    .setNumberFormat("0.00%");

  // J → from D7 (%)
  summarySheet
    .getRange(nextRow, 10)
    .setFormula(`='${dataSheet.getName()}'!D7`)
    .setNumberFormat("0.00%");

  // K → from D6 (%)
  summarySheet
    .getRange(nextRow, 11)
    .setFormula(`='${dataSheet.getName()}'!D6`)
    .setNumberFormat("0.00%");

  // L → Weighted COF (unchanged)
  summarySheet
    .getRange(nextRow, 12)
    .setFormula(`=H${nextRow}*J${nextRow}+I${nextRow}*K${nextRow}`)
    .setNumberFormat("0.00%");
}

/**
 * Master function to format sheet & add single-row summary
 */
function updateAll() {
  formatCurrentSheet();
  addSingleRowTotalPortfolioCOF();
}
