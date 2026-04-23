#!/usr/bin/env bash
set -euo pipefail

mkdir -p /app

cat > /app/index.html <<'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Transport Quote Form</title>
    <style>
      :root {
        color-scheme: light;
        font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, "Apple Color Emoji",
          "Segoe UI Emoji";
        --bg: #f6f7fb;
        --card: #ffffff;
        --border: #e5e7eb;
        --text: #111827;
        --muted: #6b7280;
        --primary: #16a34a;
        --primary-600: #15803d;
        --tab: #f3f4f6;
        --tab-active: #ffffff;
      }

      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        background: radial-gradient(1200px 600px at 20% 0%, #dbeafe, transparent 55%), var(--bg);
        color: var(--text);
      }

      main {
        min-height: 100vh;
        display: grid;
        place-items: center;
        padding: 28px 16px;
      }

      .card {
        width: min(720px, 100%);
        background: var(--card);
        border: 1px solid var(--border);
        border-radius: 16px;
        box-shadow: 0 18px 50px rgba(17, 24, 39, 0.12);
        overflow: hidden;
      }

      .stepbar {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 0;
        border-bottom: 1px solid var(--border);
        background: #f9fafb;
      }

      .tab {
        appearance: none;
        border: 0;
        background: transparent;
        padding: 14px 12px;
        font-weight: 800;
        letter-spacing: 0.02em;
        color: var(--muted);
        cursor: pointer;
      }

      .tab[aria-selected="true"] {
        background: var(--tab-active);
        color: #0f172a;
        box-shadow: inset 0 -3px 0 #2563eb;
      }

      .tab:disabled {
        cursor: not-allowed;
        opacity: 0.45;
      }

      .content {
        padding: 18px 18px 20px;
      }

      .step-title {
        margin: 0 0 12px;
        font-size: 18px;
        font-weight: 900;
        line-height: 1.25;
      }

      .panel {
        display: none;
      }

      .panel.active {
        display: block;
      }

      .fieldbox {
        border: 1px solid var(--border);
        border-radius: 14px;
        padding: 14px;
        background: #ffffff;
      }

      .field {
        display: grid;
        gap: 8px;
        padding: 10px 0;
      }

      .field + .field {
        border-top: 1px dashed #e5e7eb;
      }

      .label-row {
        display: flex;
        align-items: center;
        gap: 10px;
        font-weight: 800;
        color: #111827;
      }

      .icon {
        width: 18px;
        height: 18px;
        display: inline-grid;
        place-items: center;
        color: #2563eb;
      }

      input,
      select {
        width: 100%;
        border: 1px solid #d1d5db;
        border-radius: 10px;
        padding: 12px 12px;
        font-size: 16px;
        outline: none;
      }

      input:focus,
      select:focus {
        border-color: #2563eb;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.18);
      }

      .error {
        margin: 10px 0 0;
        color: #b91c1c;
        font-weight: 700;
        display: none;
      }

      .error.show {
        display: block;
      }

      .primary {
        margin-top: 14px;
        width: 100%;
        border: 0;
        border-radius: 12px;
        padding: 14px 14px;
        font-weight: 900;
        letter-spacing: 0.02em;
        color: #ffffff;
        background: linear-gradient(180deg, var(--primary), var(--primary-600));
        cursor: pointer;
      }

      .primary:active {
        transform: translateY(1px);
      }

      .grid-3 {
        display: grid;
        gap: 12px;
      }

      @media (min-width: 720px) {
        .grid-3 {
          grid-template-columns: 1fr 1fr 1fr;
        }
      }

      .muted {
        color: var(--muted);
        font-weight: 650;
        font-size: 13px;
        margin: 6px 0 0;
      }

      .quote-summary {
        margin-top: 16px;
        padding: 14px;
        border: 1px solid #bbf7d0;
        border-radius: 14px;
        background: #f0fdf4;
      }

      .quote-summary h3 {
        margin: 0 0 8px;
        font-size: 16px;
      }

      .quote-summary p {
        margin: 4px 0;
      }

      .quote-amount {
        font-size: 28px;
        font-weight: 950;
        color: #166534;
      }
    </style>
  </head>
  <body>
    <main>
      <section class="card" aria-label="Transport quote">
        <div class="stepbar" role="tablist" aria-label="Quote steps">
          <button id="tab-destination" class="tab" type="button" role="tab" aria-selected="true" aria-controls="panel-destination">
            Destination
          </button>
          <button id="tab-vehicle" class="tab" type="button" role="tab" aria-selected="false" aria-controls="panel-vehicle" disabled>
            Vehicle
          </button>
        </div>

        <div class="content">
          <div id="panel-destination" class="panel active" role="tabpanel" aria-labelledby="tab-destination">
            <h1 class="step-title">Transport car pickup and destination.</h1>

            <div class="fieldbox">
              <div class="field">
                <div class="label-row" for="pickup">
                  <span class="icon" aria-hidden="true" title="Search">
                    <svg viewBox="0 0 24 24" width="18" height="18" fill="none">
                      <path
                        d="M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15Z"
                        stroke="currentColor"
                        stroke-width="2"
                      />
                      <path d="M16.2 16.2 21 21" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
                    </svg>
                  </span>
                  <label for="pickup">Pickup</label>
                </div>
                <input id="pickup" aria-label="Pickup" autocomplete="off" />
              </div>

              <div class="field">
                <div class="label-row" for="delivery">
                  <span class="icon" aria-hidden="true" title="Flag">
                    <svg viewBox="0 0 24 24" width="18" height="18" fill="none">
                      <path d="M5 3v18" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
                      <path
                        d="M5 5h11l-1.2 3H5"
                        fill="currentColor"
                        opacity="0.18"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linejoin="round"
                      />
                      <path d="M5 5h11l2 6H5" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linejoin="round" />
                    </svg>
                  </span>
                  <label for="delivery">Delivery</label>
                </div>
                <input id="delivery" aria-label="Delivery" autocomplete="off" />
              </div>
            </div>

            <div id="step1-error" class="error">Please enter both pickup and delivery locations.</div>

            <button id="next-step" class="primary" type="button">VEHICLE DETAILS</button>
          </div>

          <div id="panel-vehicle" class="panel" role="tabpanel" aria-labelledby="tab-vehicle" hidden>
            <h2 class="step-title">Vehicle details</h2>

            <div class="grid-3">
              <div>
                <label class="muted" for="vehicle-year">Vehicle Year</label>
                <input id="vehicle-year" aria-label="Vehicle Year" list="vehicle-year-options" inputmode="numeric" />
                <datalist id="vehicle-year-options"></datalist>
              </div>

              <div>
                <label class="muted" for="vehicle-make">Vehicle Make</label>
                <select id="vehicle-make" aria-label="Vehicle Make">
                  <option value="" selected>Select make</option>
                  <option value="Toyota">Toyota</option>
                  <option value="Honda">Honda</option>
                  <option value="Ford">Ford</option>
                </select>
              </div>

              <div>
                <label class="muted" for="vehicle-model">Vehicle Model</label>
                <select id="vehicle-model" aria-label="Vehicle Model" disabled>
                  <option value="" selected>Select model</option>
                </select>
              </div>
            </div>

            <button id="save" class="primary" type="button">SAVE Calculate Cost</button>

            <div id="vehicle-error" class="error">Please select a valid year, make, and model.</div>

            <section id="quote-summary" class="quote-summary" role="region" aria-label="Estimated transport quote" aria-live="polite" hidden>
              <h3>Estimated transport quote</h3>
              <p id="quote-route"></p>
              <p id="quote-vehicle"></p>
              <p id="quote-amount" class="quote-amount"></p>
            </section>
          </div>
        </div>
      </section>
    </main>

    <script>
      const tabDestination = document.getElementById("tab-destination");
      const tabVehicle = document.getElementById("tab-vehicle");
      const panelDestination = document.getElementById("panel-destination");
      const panelVehicle = document.getElementById("panel-vehicle");

      const pickup = document.getElementById("pickup");
      const delivery = document.getElementById("delivery");
      const step1Error = document.getElementById("step1-error");
      const nextStep = document.getElementById("next-step");

      const yearInput = document.getElementById("vehicle-year");
      const yearList = document.getElementById("vehicle-year-options");
      const makeSelect = document.getElementById("vehicle-make");
      const modelSelect = document.getElementById("vehicle-model");
      const saveButton = document.getElementById("save");
      const vehicleError = document.getElementById("vehicle-error");
      const quoteSummary = document.getElementById("quote-summary");
      const quoteRoute = document.getElementById("quote-route");
      const quoteVehicle = document.getElementById("quote-vehicle");
      const quoteAmount = document.getElementById("quote-amount");

      const vehicleRates = {
        Toyota: { baseFee: 425, mileageRate: 0.78, models: ["Camry", "Corolla", "RAV4", "Tacoma"] },
        Honda: {
          baseFee: 415,
          mileageRate: 0.76,
          models: ["Civic", "Accord", "CR-V", "Pilot", "HR-V", "Passport", "Ridgeline", "Insight", "Odyssey"],
        },
        Ford: {
          baseFee: 440,
          mileageRate: 0.81,
          models: ["F-150", "Bronco", "Mustang", "Explorer", "Escape", "Edge", "Ranger", "Maverick", "Expedition"],
        },
      };

      const routeDistances = {
        "los angeles|houston": 1547,
        "houston|los angeles": 1547,
      };

      const currentYear = new Date().getFullYear();
      for (let year = currentYear; year >= 1980; year -= 1) {
        const opt = document.createElement("option");
        opt.value = String(year);
        yearList.appendChild(opt);
      }

      function setStep(index) {
        const isDestination = index === 0;

        tabDestination.setAttribute("aria-selected", isDestination ? "true" : "false");
        tabVehicle.setAttribute("aria-selected", isDestination ? "false" : "true");

        panelDestination.classList.toggle("active", isDestination);
        panelVehicle.classList.toggle("active", !isDestination);

        panelDestination.hidden = !isDestination;
        panelVehicle.hidden = isDestination;
      }

      function populateModels(makeSelectEl, modelSelectEl) {
        const make = makeSelectEl.value;
        modelSelectEl.innerHTML = "";

        const placeholder = document.createElement("option");
        placeholder.value = "";
        placeholder.textContent = "Select model";
        placeholder.selected = true;
        modelSelectEl.appendChild(placeholder);

        if (!make) {
          modelSelectEl.disabled = true;
          return;
        }

        const models = vehicleRates[make]?.models || [];
        for (const m of models) {
          const opt = document.createElement("option");
          opt.value = m;
          opt.textContent = m;
          modelSelectEl.appendChild(opt);
        }

        modelSelectEl.disabled = models.length === 0;
      }

      function normalizeLocation(value) {
        return value.trim().toLowerCase().replace(/\s+/g, " ");
      }

      function getDistanceMiles(pickupValue, deliveryValue) {
        const key = `${normalizeLocation(pickupValue)}|${normalizeLocation(deliveryValue)}`;
        return routeDistances[key] || 900;
      }

      function calculateQuote(details) {
        const rate = vehicleRates[details.make];
        const distanceMiles = getDistanceMiles(details.pickup, details.delivery);
        const vehicleAge = Math.max(0, currentYear - Number(details.year));

        return Math.round(rate.baseFee + distanceMiles * rate.mileageRate + vehicleAge * 12);
      }

      function formatCurrency(amount) {
        return new Intl.NumberFormat("en-US", {
          style: "currency",
          currency: "USD",
          maximumFractionDigits: 0,
        }).format(amount);
      }

      tabDestination.addEventListener("click", () => {
        if (tabDestination.disabled) return;
        setStep(0);
      });

      tabVehicle.addEventListener("click", () => {
        if (tabVehicle.disabled) return;
        setStep(1);
      });

      nextStep.addEventListener("click", () => {
        const p = pickup.value.trim();
        const d = delivery.value.trim();

        if (!p || !d) {
          step1Error.classList.add("show");
          return;
        }

        step1Error.classList.remove("show");
        tabVehicle.disabled = false;
        setStep(1);
      });

      makeSelect.addEventListener("change", () => {
        populateModels(makeSelect, modelSelect);
        quoteSummary.hidden = true;
      });

      saveButton.addEventListener("click", () => {
        const year = Number(yearInput.value);
        const make = makeSelect.value;
        const model = modelSelect.value;

        const validYear = Number.isInteger(year) && year >= 1980 && year <= currentYear;
        const validModel = Boolean(make && model && vehicleRates[make]?.models.includes(model));

        if (!validYear || !validModel) {
          vehicleError.classList.add("show");
          quoteSummary.hidden = true;
          return;
        }

        vehicleError.classList.remove("show");

        const details = {
          pickup: pickup.value.trim(),
          delivery: delivery.value.trim(),
          year,
          make,
          model,
        };
        const amount = calculateQuote(details);

        quoteRoute.textContent = `${details.pickup} to ${details.delivery}`;
        quoteVehicle.textContent = `${details.year} ${details.make} ${details.model}`;
        quoteAmount.textContent = formatCurrency(amount);
        quoteSummary.hidden = false;
      });

      populateModels(makeSelect, modelSelect);
      setStep(0);
    </script>
  </body>
</html>
EOF

if [ -d /workspace ]; then
  cp /app/index.html /workspace/index.html || true
fi
