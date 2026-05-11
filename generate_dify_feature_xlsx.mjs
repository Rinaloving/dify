import fs from "node:fs";
import path from "node:path";
import http from "node:http";
import ExcelJS from "exceljs";

const repoRoot = process.cwd();
const templatePath = path.join(repoRoot, "Higo体验官H5功能清单-2026年4月13日 - 副本.xlsx");
const targetPath = path.join(repoRoot, "Dify功能清单-按Higo格式.xlsx");
const inspectionPath = path.join(repoRoot, "dify_template_inspection.json");
const reportPath = path.join(repoRoot, "dify_xlsx_generation_report.json");

function normalizeValue(value) {
  if (value === null || value === undefined) return "";
  if (typeof value === "object") {
    if ("text" in value && typeof value.text === "string") return value.text;
    if ("richText" in value && Array.isArray(value.richText)) {
      return value.richText.map((item) => item.text || "").join("");
    }
    if ("formula" in value && value.result !== undefined) return String(value.result ?? "");
    return JSON.stringify(value);
  }
  return String(value);
}

async function inspectTemplate() {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(templatePath);

  const summary = {
    templatePath,
    sheetNames: workbook.worksheets.map((sheet) => sheet.name),
    sheets: workbook.worksheets.map((sheet) => {
      const rows = [];
      for (let rowNumber = 1; rowNumber <= Math.min(sheet.rowCount, 30); rowNumber += 1) {
        const row = sheet.getRow(rowNumber);
        const values = [];
        for (let col = 1; col <= Math.min(sheet.columnCount || 20, 12); col += 1) {
          values.push(normalizeValue(row.getCell(col).value));
        }
        if (values.some((value) => value !== "")) {
          rows.push({ rowNumber, values });
        }
      }

      return {
        name: sheet.name,
        rowCount: sheet.rowCount,
        columnCount: sheet.columnCount,
        actualRowCount: sheet.actualRowCount,
        actualColumnCount: sheet.actualColumnCount,
        merges: Object.keys(sheet._merges || {}),
        sampleRows: rows,
      };
    }),
  };

  fs.writeFileSync(inspectionPath, JSON.stringify(summary, null, 2), "utf8");
  return summary;
}

async function generateWorkbook() {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(templatePath);
  fs.writeFileSync(
    reportPath,
    JSON.stringify(
      {
        created: false,
        message: "Generation logic not implemented yet.",
      },
      null,
      2
    ),
    "utf8"
  );
  await workbook.xlsx.writeFile(targetPath);
}

async function startServer(port, payload) {
  const server = http.createServer((_req, res) => {
    res.writeHead(200, { "Content-Type": "application/json; charset=utf-8" });
    res.end(JSON.stringify(payload, null, 2));
  });
  await new Promise((resolve) => server.listen(port, "127.0.0.1", resolve));
  console.log(`READY http://127.0.0.1:${port}`);
}

async function main() {
  const mode = process.argv[2];
  if (mode === "inspect-and-serve") {
    const summary = await inspectTemplate();
    await startServer(45781, summary);
    return;
  }

  if (mode === "generate-and-serve") {
    await generateWorkbook();
    const payload = fs.existsSync(reportPath)
      ? JSON.parse(fs.readFileSync(reportPath, "utf8"))
      : { created: fs.existsSync(targetPath) };
    await startServer(45782, payload);
    return;
  }

  throw new Error(`Unsupported mode: ${mode}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
