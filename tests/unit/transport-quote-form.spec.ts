import { describe, expect, it } from "vitest";
import fs from "node:fs";

const appHtmlPath = "/app/index.html";
const quote = String.raw`["']`;

function readHtml() {
  if (!fs.existsSync(appHtmlPath)) {
    throw new Error(`Missing ${appHtmlPath}`);
  }

  return fs.readFileSync(appHtmlPath, "utf8");
}

describe("transport quote form markup contract", () => {
  /**
   * Contract: the shipped HTML should expose the same chrome strings the UI tests rely on
   * (title, hero copy, step labels, and the primary CTA label).
   */
  it("includes the expected page chrome and step labels", () => {
    const html = readHtml();

    expect(html).toMatch(/<title>\s*Transport Quote Form\s*<\/title>/);
    expect(html).toMatch(/Transport car pickup and destination\.?/);
    expect(html).toMatch(new RegExp(`role=${quote}tablist${quote}`));
    expect(html).toMatch(new RegExp(`role=${quote}tab${quote}`));
    expect(html).toContain("Destination");
    expect(html).toContain("Vehicle");
    expect(html).toContain("VEHICLE DETAILS");
    expect(html).toContain("SAVE Calculate Cost");
  });

  /**
   * Contract: key inputs must remain discoverable to assistive tech and the model control must
   * start disabled until a make is chosen (mirrors the Playwright flow).
   */
  it("includes accessible labels and the dependent vehicle model control", () => {
    const html = readHtml();

    expect(html).toMatch(new RegExp(`aria-label=${quote}Pickup${quote}`));
    expect(html).toMatch(new RegExp(`aria-label=${quote}Delivery${quote}`));
    expect(html).toMatch(new RegExp(`aria-label=${quote}Vehicle Year${quote}`));
    expect(html).toMatch(new RegExp(`aria-label=${quote}Vehicle Make${quote}`));
    expect(html).toMatch(new RegExp(`aria-label=${quote}Vehicle Model${quote}`));
    expect(html).toMatch(/<option[^>]*value=["']["'][^>]*>\s*Select model\s*<\/option>/i);
    expect(html).toMatch(new RegExp(`id=${quote}vehicle-model${quote}[\\s\\S]*disabled|disabled[\\s\\S]*id=${quote}vehicle-model${quote}`));
  });

  /**
   * Contract: step-one and step-two validation copy, success confirmation, and the year datalist hook.
   */
  it("includes validation messages, Success confirmation, and the year datalist hook", () => {
    const html = readHtml();

    expect(html).toMatch(/Please enter both pickup and delivery locations\.?/);
    expect(html).toMatch(/Pickup and delivery must be different locations\.?/);
    expect(html).toMatch(/Please select a valid year, make, and model\.?/);
    expect(html).toContain("Success!");
    expect(html).toMatch(new RegExp(`list=${quote}vehicle-year-options${quote}`));
  });

  /**
   * Contract: Toyota coverage, populateModels wiring, and the exact year-generation loop must be
   * present as plain substrings so reviewers can grep the file without executing JS.
   */
  it("includes Toyota models, populateModels, and the year loop substring", () => {
    const html = readHtml();

    expect(html).toContain("Toyota");
    expect(html).toContain("Camry");
    expect(html).toContain("Corolla");
    expect(html).toContain("RAV4");
    expect(html).toContain("Tacoma");
    expect(html).toContain("populateModels");
    expect(html).toContain("for (let year = currentYear; year >= 1980; year -= 1)");
  });

  /**
   * Contract: the task is intentionally a single static HTML file with no framework assets,
   * build-tool entrypoints, or runtime network calls for vehicle/year data.
   */
  it("stays self-contained without external assets or API calls", () => {
    const html = readHtml();

    expect(html).not.toMatch(/<script\b[^>]*\bsrc=/i);
    expect(html).not.toMatch(new RegExp(`<link\\b[^>]*rel=${quote}stylesheet${quote}`, "i"));
    expect(html).not.toMatch(/\bfetch\s*\(/);
    expect(html).not.toMatch(/\bXMLHttpRequest\b/);
    expect(html).not.toMatch(/\bimport\s+.*\bfrom\b/);
  });
});
