import { expect, test } from "@playwright/test";

test("step 1 is shown first and future steps stay locked", async ({ page }) => {
  await page.goto("/");

  await expect(page).toHaveTitle(/Transport Quote Form/i);
  await expect(page.getByRole("heading", { name: "Transport car pickup and destination." })).toBeVisible();

  const destinationTab = page.getByRole("tab", { name: /destination/i });
  const vehicleTab = page.getByRole("tab", { name: /vehicle/i });

  await expect(destinationTab).toHaveAttribute("aria-selected", "true");
  await expect(vehicleTab).toBeDisabled();
  await expect(page.getByRole("button", { name: "VEHICLE DETAILS" })).toBeVisible();
});

test("users can progress to vehicle details and load dependent models", async ({ page }) => {
  await page.goto("/");

  await page.getByLabel("Pickup").fill("Los Angeles");
  await page.getByLabel("Delivery").fill("Houston");
  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  const vehicleTab = page.getByRole("tab", { name: /vehicle/i });
  const yearField = page.getByLabel("Vehicle Year");
  const makeSelect = page.getByLabel("Vehicle Make");
  const modelSelect = page.getByLabel("Vehicle Model");

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

test("step 1 validates blank locations before unlocking step 2", async ({ page }) => {
  await page.goto("/");

  await page.getByRole("button", { name: "VEHICLE DETAILS" }).click();

  await expect(page.getByText("Please enter both pickup and delivery locations.")).toBeVisible();
  await expect(page.getByRole("tab", { name: /vehicle/i })).toBeDisabled();
});
