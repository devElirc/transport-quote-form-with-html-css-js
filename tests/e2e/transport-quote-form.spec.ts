import { expect, test } from "@playwright/test";

test("step 1 is shown first and future steps stay locked", async ({ page }) => {
  await page.goto("/");

  await expect(page).toHaveTitle(/Transport Quote Form/i);
  await expect(page.getByRole("heading", { name: /^Transport car pickup and destination\.?$/ })).toBeVisible();

  const destinationTab = page.getByRole("tab", { name: /destination/i });
  const vehicleTab = page.getByRole("tab", { name: /vehicle/i });

  await expect(destinationTab).toHaveAttribute("aria-selected", "true");
  await expect(vehicleTab).toBeDisabled();
  await expect(page.getByRole("button", { name: "VEHICLE DETAILS" })).toBeVisible();
});

test("users can progress to vehicle details and load dependent models", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("textbox", { name: "Pickup" }).fill("Los Angeles");
  await page.getByRole("textbox", { name: "Delivery" }).fill("Houston");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  const vehicleTab = page.getByRole("tab", { name: /vehicle/i });
  const yearField = page.getByRole("combobox", { name: "Vehicle Year" });
  const makeSelect = page.getByRole("combobox", { name: "Vehicle Make" });
  const modelSelect = page.getByRole("combobox", { name: "Vehicle Model" });

  await expect(vehicleTab).toHaveAttribute("aria-selected", "true");
  await expect(page.getByRole("heading", { name: /vehicle details/i })).toBeVisible();
  await expect(modelSelect).toBeDisabled();

  const currentYear = new Date().getFullYear().toString();
  await expect(page.locator("#vehicle-year-options option").first()).toHaveAttribute("value", currentYear);
  await expect(page.locator("#vehicle-year-options option").last()).toHaveAttribute("value", "1980");

  await makeSelect.selectOption("Toyota");
  await expect(modelSelect).toBeEnabled();
  await expect(modelSelect.locator("option")).toContainText(["Select model", "Camry", "Corolla", "RAV4", "Tacoma"]);

  await yearField.fill("2024");
  await modelSelect.selectOption("Camry");
  await expect(page.getByRole("button", { name: "SAVE Calculate Cost" })).toBeVisible();
});

test("step 2 validates vehicle fields before showing a calculated quote", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("textbox", { name: "Pickup" }).fill("  Los   Angeles ");
  await page.getByRole("textbox", { name: "Delivery" }).fill("HOUSTON");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();
  await expect(page.getByText(/Please select a valid year, make, and model\.?/)).toBeVisible();

  const currentYear = new Date().getFullYear();
  const quotedYear = currentYear - 2;
  const expectedQuote = 425 + 1547 * 0.78 + (currentYear - quotedYear) * 12;
  const expectedCurrency = new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(Math.round(expectedQuote));

  await page.getByRole("combobox", { name: "Vehicle Year" }).fill(String(quotedYear));
  await page.getByRole("combobox", { name: "Vehicle Make" }).selectOption("Toyota");
  await page.getByRole("combobox", { name: "Vehicle Model" }).selectOption("Camry");
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();

  await expect(page.getByRole("heading", { name: "Estimated transport quote" })).toBeVisible();
  await expect(page.getByText("Los Angeles to Houston")).toBeVisible();
  await expect(page.getByText(`${quotedYear} Toyota Camry`)).toBeVisible();
  await expect(page.getByText(expectedCurrency)).toBeVisible();
});

test("reverse route direction resolves to the same distance", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("textbox", { name: "Pickup" }).fill("Houston");
  await page.getByRole("textbox", { name: "Delivery" }).fill("Los Angeles");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  const currentYear = new Date().getFullYear();
  const quotedYear = currentYear - 2;
  const expectedQuote = 425 + 1547 * 0.78 + (currentYear - quotedYear) * 12;
  const expectedCurrency = new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(Math.round(expectedQuote));

  await page.getByRole("combobox", { name: "Vehicle Year" }).fill(String(quotedYear));
  await page.getByRole("combobox", { name: "Vehicle Make" }).selectOption("Toyota");
  await page.getByRole("combobox", { name: "Vehicle Model" }).selectOption("Camry");
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();

  await expect(page.getByRole("heading", { name: "Estimated transport quote" })).toBeVisible();
  await expect(page.getByText("Houston to Los Angeles")).toBeVisible();
  await expect(page.getByText(`${quotedYear} Toyota Camry`)).toBeVisible();
  await expect(page.getByText(expectedCurrency)).toBeVisible();
});

test("changing the make resets model selection and hides the existing quote", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("textbox", { name: "Pickup" }).fill("Los Angeles");
  await page.getByRole("textbox", { name: "Delivery" }).fill("Houston");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  const yearField = page.getByRole("combobox", { name: "Vehicle Year" });
  const makeSelect = page.getByRole("combobox", { name: "Vehicle Make" });
  const modelSelect = page.getByRole("combobox", { name: "Vehicle Model" });
  const quoteHeading = page.getByRole("heading", { name: "Estimated transport quote" });

  const currentYear = new Date().getFullYear();
  await yearField.fill(String(currentYear - 2));
  await makeSelect.selectOption("Toyota");
  await modelSelect.selectOption("Camry");
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();
  await expect(quoteHeading).toBeVisible();

  await makeSelect.selectOption("Honda");
  await expect(quoteHeading).toBeHidden();
  await expect(modelSelect).toHaveValue("");
});

test("unlocked tabs let users revisit destination and return to vehicle details", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("textbox", { name: "Pickup" }).fill("Los Angeles");
  await page.getByRole("textbox", { name: "Delivery" }).fill("Houston");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  const destinationTab = page.getByRole("tab", { name: /destination/i });
  const vehicleTab = page.getByRole("tab", { name: /vehicle/i });

  await expect(vehicleTab).toHaveAttribute("aria-selected", "true");
  await destinationTab.click();
  await expect(destinationTab).toHaveAttribute("aria-selected", "true");
  await expect(page.getByRole("heading", { name: /^Transport car pickup and destination\.?$/ })).toBeVisible();

  await vehicleTab.click();
  await expect(vehicleTab).toHaveAttribute("aria-selected", "true");
  await expect(page.getByRole("heading", { name: /vehicle details/i })).toBeVisible();
});

test("out-of-range vehicle years keep the user on step 2 without showing a quote", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("textbox", { name: "Pickup" }).fill("Los Angeles");
  await page.getByRole("textbox", { name: "Delivery" }).fill("Houston");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  const yearField = page.getByRole("combobox", { name: "Vehicle Year" });
  const makeSelect = page.getByRole("combobox", { name: "Vehicle Make" });
  const modelSelect = page.getByRole("combobox", { name: "Vehicle Model" });

  await makeSelect.selectOption("Toyota");
  await modelSelect.selectOption("Camry");

  await yearField.fill("1979");
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();
  await expect(page.getByText(/Please select a valid year, make, and model\.?/)).toBeVisible();
  await expect(page.getByRole("heading", { name: "Estimated transport quote" })).toBeHidden();

  await yearField.fill(String(new Date().getFullYear() + 1));
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();
  await expect(page.getByText(/Please select a valid year, make, and model\.?/)).toBeVisible();
  await expect(page.getByRole("heading", { name: "Estimated transport quote" })).toBeHidden();
});

test("clearing the vehicle make disables models and restores the default model option", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("textbox", { name: "Pickup" }).fill("Los Angeles");
  await page.getByRole("textbox", { name: "Delivery" }).fill("Houston");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  const makeSelect = page.getByRole("combobox", { name: "Vehicle Make" });
  const modelSelect = page.getByRole("combobox", { name: "Vehicle Model" });

  await makeSelect.selectOption("Toyota");
  await modelSelect.selectOption("Camry");
  await expect(modelSelect).toHaveValue("Camry");

  await makeSelect.selectOption("");
  await expect(modelSelect).toBeDisabled();
  await expect(modelSelect).toHaveValue("");
  await expect(modelSelect.locator("option")).toHaveText(["Select model"]);
});

test("step 1 validates blank locations before unlocking step 2", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  await expect(page.getByText(/Please enter both pickup and delivery locations\.?/)).toBeVisible();
  await expect(page.getByRole("tab", { name: /vehicle/i })).toBeDisabled();
});
