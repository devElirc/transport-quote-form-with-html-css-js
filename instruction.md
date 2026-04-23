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
When the user clicks the button, move to Step 2 only if both inputs have text after trimming spaces. 
If not, stay on Step 1 and show this exact message: Please enter both pickup and delivery locations.

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

Clicking SAVE Calculate Cost must validate the Step 2 fields before showing a quote. 
The user must enter a Vehicle Year between 1980 and the current year, choose a Vehicle Make, and choose a real Vehicle Model. 
If any of those values are missing or invalid, keep the user on Step 2 and show this exact message: Please select a valid year, make, and model.

Your in-page JavaScript data must include per-make quote settings with a base fee and mileage rate. 
Toyota must use baseFee 425 and mileageRate 0.78. Use that same data source for both the make/model dropdown behavior and quote calculation.

Add route-distance data in plain in-page JavaScript. At minimum, the normalized route Los Angeles to Houston must resolve to 1547 miles, and the reverse direction must work too. Unknown routes may use a fallback distance.

Create a JavaScript function named calculateQuote(details). 
The file must contain that exact function name as a substring. 
The function should calculate: Math.round(baseFee + distanceMiles * mileageRate + vehicleAge * 12)
where vehicleAge is the current year minus the selected vehicle year, but never less than 0.

After a valid SAVE Calculate Cost click, 
show a quote summary panel with aria-live="polite". 
The panel must include the heading text Estimated transport quote, the route in the format Pickup to Delivery, the selected vehicle in the format Year Make Model, and the calculated amount formatted as US dollars.

The /app/index.html source must also include the literal substrings calculateQuote, baseFee, mileageRate, routeDistances, Estimated transport quote, and Please select a valid year, make, and model.

Keep everything frontend-only, with no external API calls.

Route matching should still work even when the user types city names with extra spaces or different capital letters. For example, " Los Angeles " and "HOUSTON" should match the same route as "Los Angeles" and "Houston".

If the user selects a make and model, and then changes the make, the model dropdown should go back to the default option, "Select model". 
If the quote summary is already showing, hide it until the user selects a valid model again.
