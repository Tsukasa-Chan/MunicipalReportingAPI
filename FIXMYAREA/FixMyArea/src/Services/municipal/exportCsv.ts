import type { Issue, Report } from "@/Models/municipal";

/** Generate downloadable PDFs without changing the existing export call sites or adding dependencies. */
type Cell = string | number | null | undefined;

/** Retained for compatibility with any existing consumers of this utility. */
function cell(value: Cell): string {
  if (value === null || value === undefined) return "";
  const text = String(value);
  return /[",\r\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

export function toCsv(headers: string[], rows: Cell[][]): string {
  return [headers, ...rows].map((row) => row.map(cell).join(",")).join("\r\n");
}

// Standard PDF fonts use WinAnsi encoding. Replace characters outside that encoding,
// while keeping common punctuation and accented Latin characters readable.
function pdfText(value: string): string {
  return value
    .replace(/[\u2018\u2019]/g, "'")
    .replace(/[\u201C\u201D]/g, '"')
    .replace(/[\u2013\u2014]/g, "-")
    .replace(/\u2026/g, "...")
    .replace(/\u00A0/g, " ")
    .replace(/[^\x20-\x7E\xA0-\xFF]/g, "?");
}

function literal(text: string): string {
  return `(${pdfText(text).replace(/\\/g, "\\\\").replace(/\(/g, "\\(").replace(/\)/g, "\\)")})`;
}

function wrap(value: string, maxChars: number): string[] {
  const lines: string[] = [];
  for (const paragraph of value.replace(/\r\n?/g, "\n").split("\n")) {
    let line = "";
    for (const word of paragraph.split(/\s+/)) {
      if (!word) continue;
      if (line && line.length + word.length + 1 > maxChars) {
        lines.push(line);
        line = "";
      }
      if (word.length > maxChars) {
        if (line) lines.push(line);
        for (let pos = 0; pos < word.length; pos += maxChars) {
          const chunk = word.slice(pos, pos + maxChars);
          if (chunk.length === maxChars) lines.push(chunk);
          else line = chunk;
        }
      } else {
        line = line ? `${line} ${word}` : word;
      }
    }
    lines.push(line);
  }
  return lines;
}

/** Small self-contained PDF writer: one clearly labelled entry per issue or report. */
function makePdf(title: string, headers: string[], rows: Cell[][]): Blob {
  const width = 595.28;
  const height = 841.89;
  const left = 45;
  const bottom = 51;
  const pages: string[] = [];
  let commands: string[] = [];
  let y = 0;
  let pageNumber = 0;

  const text = (value: string, x: number, baseline: number, size: number, bold = false) => {
    commands.push(`BT /${bold ? "F2" : "F1"} ${size} Tf 1 0 0 1 ${x.toFixed(2)} ${baseline.toFixed(2)} Tm ${literal(value)} Tj ET`);
  };
  const newPage = () => {
    if (pageNumber > 0) pages.push(commands.join("\n"));
    pageNumber++;
    commands = [];
    commands.push("0.16 0.15 0.14 rg");
    text("Fix My Area", left, height - 45, 11, true);
    commands.push("0.79 0.31 0.11 rg");
    text(title, left, height - 76, 19, true);
    commands.push("0.16 0.15 0.14 rg");
    text(`Generated: ${new Date().toISOString().slice(0, 10)}    Total: ${rows.length}`, left, height - 96, 9);
    commands.push(`0.88 0.83 0.80 RG 0.7 w ${left} ${(height - 111).toFixed(2)} m ${(width - left).toFixed(2)} ${(height - 111).toFixed(2)} l S`);
    text(`Page ${pageNumber}`, width - 93, 30, 9);
    y = height - 136;
  };
  const requireSpace = (space: number) => {
    if (y - space < bottom) newPage();
  };

  newPage();
  rows.forEach((row, index) => {
    requireSpace(31);
    commands.push("0.79 0.31 0.11 rg");
    text(`${title === "Issues" ? "Issue" : "Report"} ${index + 1}`, left, y, 12, true);
    commands.push("0.16 0.15 0.14 rg");
    y -= 23;
    headers.forEach((header, column) => {
      const value = row[column] === null || row[column] === undefined ? "" : String(row[column]);
      const lines = wrap(value || "-", 80);
      requireSpace(17 + lines.length * 12);
      text(`${header}:`, left + 8, y, 9, true);
      y -= 13;
      lines.forEach((line) => {
        text(line, left + 16, y, 9);
        y -= 12;
      });
      y -= 5;
    });
    requireSpace(13);
    commands.push(`0.88 0.83 0.80 RG 0.5 w ${left} ${y.toFixed(2)} m ${(width - left).toFixed(2)} ${y.toFixed(2)} l S`);
    y -= 21;
  });
  pages.push(commands.join("\n"));

  // Write PDF objects and cross-reference offsets in Latin-1 (one byte per character).
  const objects: string[] = [];
  const add = (object: string) => { objects.push(object); return objects.length; };
  const catalogId = add("");
  const pagesId = add("");
  const regularId = add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>");
  const boldId = add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>");
  const pageIds: number[] = [];
  pages.forEach((content) => {
    const streamId = add(`<< /Length ${content.length} >>\nstream\n${content}\nendstream`);
    pageIds.push(add(`<< /Type /Page /Parent ${pagesId} 0 R /MediaBox [0 0 ${width} ${height}] /Resources << /Font << /F1 ${regularId} 0 R /F2 ${boldId} 0 R >> >> /Contents ${streamId} 0 R >>`));
  });
  objects[catalogId - 1] = `<< /Type /Catalog /Pages ${pagesId} 0 R >>`;
  objects[pagesId - 1] = `<< /Type /Pages /Kids [${pageIds.map((id) => `${id} 0 R`).join(" ")}] /Count ${pageIds.length} >>`;

  let pdf = "%PDF-1.4\n";
  const offsets = [0];
  objects.forEach((object, index) => {
    offsets.push(pdf.length);
    pdf += `${index + 1} 0 obj\n${object}\nendobj\n`;
  });
  const xrefOffset = pdf.length;
  pdf += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  offsets.slice(1).forEach((offset) => { pdf += `${String(offset).padStart(10, "0")} 00000 n \n`; });
  pdf += `trailer\n<< /Size ${objects.length + 1} /Root ${catalogId} 0 R >>\nstartxref\n${xrefOffset}\n%%EOF`;
  const bytes = Uint8Array.from(pdf, (character) => character.charCodeAt(0));
  return new Blob([bytes], { type: "application/pdf" });
}

function download(baseName: string, headers: string[], rows: Cell[][]) {
  const day = new Date().toISOString().slice(0, 10);
  const title = baseName === "fixmyarea-issues" ? "Issues" : "Reports";
  const url = URL.createObjectURL(makePdf(title, headers, rows));
  const link = document.createElement("a");
  link.href = url;
  link.download = `${baseName}-${day}.pdf`;
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 1000);
}

/** "2026-10-04T09:30:00Z" -> "2026-10-04 09:30" */
const when = (iso: string | null | undefined) => (iso ? iso.slice(0, 16).replace("T", " ") : "");

export function downloadIssuesCsv(issues: Issue[]) {
  download(
    "fixmyarea-issues",
    ["Issue", "Category", "Specific issue", "Location", "Latitude", "Longitude", "Status", "Supervisor", "Resident reports", "Created", "Last updated"],
    issues.map((i) => [i.issueNumber, i.category, i.issueType, i.location, i.latitude, i.longitude, i.status, i.supervisorName ?? "Unassigned", i.reportCount, when(i.createdAt), when(i.updatedAt)]),
  );
}

export function downloadReportsCsv(reports: Report[], issues: Issue[]) {
  const issueById = new Map(issues.map((i) => [i.id, i] as const));
  download(
    "fixmyarea-reports",
    ["Report", "Issue", "Category", "Specific issue", "Resident", "Description", "Location", "Photo link", "Submitted"],
    reports.map((r) => {
      const issue = issueById.get(r.issueId);
      return [r.id, issue?.issueNumber ?? "", issue?.category ?? "", issue?.issueType ?? "", r.residentName, r.description, r.location, r.photoUrl, when(r.submittedAt)];
    }),
  );
}
