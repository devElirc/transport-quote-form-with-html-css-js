Build a simple transport quote form as one static page using HTML, CSS, and plain JavaScript only.

Implement everything in /app/index.html. Do not add a bundler, framework app scaffold, or extra build tooling beyond what you put in that single HTML file.

The page must include this exact document title: <title>Transport Quote Form</title>.

Make it a small card with two steps: Destination and Vehicle.

At the top, add a step bar that behaves like tabs. Use role="tablist" on the wrapper, role="tab" on each step, and mark the active step with aria-selected.

The two tab labels must include the text Destination and Vehicle (those words are what the UI should show for the steps).

The current step should look active.

Any step the user has not reached yet should stay disabled.

Show the active step content inside the same card.

Use this exact title for Step 1: Transport car pickup and destination.

Inside a bordered box, add two stacked input fields: Pickup with a small search icon, and Delivery with a small flag icon.

On the actual inputs, use aria-label="Pickup" and aria-label="Delivery".

Below the inputs, add a full-width green button labeled exactly VEHICLE DETAILS.

When the user clicks the button, move to Step 2 only if both inputs have text after trimming spaces. If not, stay on Step 1 and show this exact message: Please enter both pickup and delivery locations.

Step 2 should show a heading that includes Vehicle details.

Add a Vehicle Year field with aria-label="Vehicle Year" and list="vehicle-year-options".

Add <datalist id="vehicle-year-options"> and generate years from the current year down to 1980.

The file must contain this exact loop text: for (let year = currentYear; year >= 1980; year -= 1)

Add a Vehicle Make field using a <select> with aria-label="Vehicle Make".

Add a Vehicle Model field using a <select id="vehicle-model"> with aria-label="Vehicle Model".

Keep the model field disabled at first, then enable it and load the matching options after a make is selected.

Create a JavaScript function named populateModels(makeSelect, modelSelect). The file must contain that exact function name as a substring.

Use realistic make and model lists as plain in-page JavaScript data, like a simple object or map.

At minimum, Toyota must include Camry, Corolla, RAV4, and Tacoma.

The /app/index.html source must also include the literal substrings Toyota, Camry, Corolla, RAV4, Tacoma, populateModels, and the exact year-generation loop text for (let year = currentYear; year >= 1980; year -= 1).

In the model <select>, make the first option exactly Select model, and keep it selected until the user picks a real model.

Under the fields, add a button with this exact text: SAVE Calculate Cost.

Keep everything frontend-only, with no external API calls.