import { expect, test } from "@playwright/test";

test("step 1 is shown first and future steps stay locked", async ({ page }) => {
  await page.goto("/");

  await expect(page).toHaveTitle(/Transport Quote Form/i);
  await expect(page.getByRole("tablist")).toBeVisible();
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
  await expect(vehicleTab).toBeEnabled();
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

test("step 2 shows validation until fields are valid, then shows Success!", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("textbox", { name: "Pickup" }).fill("Los Angeles");
  await page.getByRole("textbox", { name: "Delivery" }).fill("Houston");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();
  await expect(page.getByText(/Please select a valid year, make, and model\.?/)).toBeVisible();
  await expect(page.getByText(/^Success!$/)).toBeHidden();

  const currentYear = new Date().getFullYear();
  const quotedYear = currentYear - 2;
  await page.getByRole("combobox", { name: "Vehicle Year" }).fill(String(quotedYear));
  await page.getByRole("combobox", { name: "Vehicle Make" }).selectOption("Toyota");
  await page.getByRole("combobox", { name: "Vehicle Model" }).selectOption("Camry");
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();

  await expect(page.getByText(/^Success!$/)).toBeVisible();
  await expect(page.getByText(/Please select a valid year, make, and model\.?/)).toBeHidden();
});

test("out-of-range vehicle years stay on step 2 without showing Success!", async ({ page }) => {
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
  await expect(page.getByText(/^Success!$/)).toBeHidden();

  await yearField.fill(String(new Date().getFullYear() + 1));
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();
  await expect(page.getByText(/Please select a valid year, make, and model\.?/)).toBeVisible();
  await expect(page.getByText(/^Success!$/)).toBeHidden();
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

test("a tampered model option is rejected because it is not a real model", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("textbox", { name: "Pickup" }).fill("Los Angeles");
  await page.getByRole("textbox", { name: "Delivery" }).fill("Houston");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  const currentYear = new Date().getFullYear();
  await page.getByRole("combobox", { name: "Vehicle Year" }).fill(String(currentYear - 2));
  await page.getByRole("combobox", { name: "Vehicle Make" }).selectOption("Toyota");

  await page.locator("#vehicle-model").evaluate((select) => {
    const option = document.createElement("option");
    option.value = "Counterfeit";
    option.textContent = "Counterfeit";
    select.appendChild(option);
  });
  await page.getByRole("combobox", { name: "Vehicle Model" }).selectOption("Counterfeit");
  await page.getByRole("button", { name: "SAVE Calculate Cost" }).click();

  await expect(page.getByText(/Please select a valid year, make, and model\.?/)).toBeVisible();
  await expect(page.getByText(/^Success!$/)).toBeHidden();
});

test("step 1 validates blank locations before unlocking step 2", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  await expect(page.getByText(/Please enter both pickup and delivery locations\.?/)).toBeVisible();
  await expect(page.getByRole("tab", { name: /vehicle/i })).toBeDisabled();
});

test("step 1 treats whitespace-only locations as blank after trimming", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("textbox", { name: "Pickup" }).fill("     ");
  await page.getByRole("textbox", { name: "Delivery" }).fill("Houston");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  await expect(page.getByText(/Please enter both pickup and delivery locations\.?/)).toBeVisible();
  await expect(page.getByRole("tab", { name: /vehicle/i })).toBeDisabled();
  await expect(page.getByRole("heading", { name: /^Transport car pickup and destination\.?$/ })).toBeVisible();
});

test("step 1 rejects same-city pickup and delivery after normalization", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("textbox", { name: "Pickup" }).fill("Los Angeles");
  await page.getByRole("textbox", { name: "Delivery" }).fill("  los   angeles  ");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  await expect(page.getByText(/Pickup and delivery must be different locations\.?/)).toBeVisible();
  await expect(page.getByRole("tab", { name: /vehicle/i })).toBeDisabled();
});
