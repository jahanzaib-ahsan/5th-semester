// Step 4: Mathematical Validation

const inputQuestion = document.getElementById("inputQuestion");
const runValidationButton = document.getElementById("runValidation");
const normalisedExpressionElement = document.getElementById(
  "normalisedExpression",
);
const validationLog = document.getElementById("validationLog");
const readyMessage = document.getElementById("readyMessage");
const goToStep5Button = document.getElementById("goToStep5");

function clearLog() {
  while (validationLog.firstChild) {
    validationLog.removeChild(validationLog.firstChild);
  }
}

function addLogEntry(message) {
  const item = document.createElement("li");
  item.textContent = message;
  validationLog.appendChild(item);
}

function normaliseSymbols(text) {
  let result = text;
  const replacements = [
    { from: /×/g, to: "*" },
    { from: /÷/g, to: "/" },
    { from: /−/g, to: "-" },
    { from: /\s+/g, to: " " },
  ];

  replacements.forEach((rule) => {
    result = result.replace(rule.from, rule.to);
  });

  return result.trim();
}

function hasEquationStructure(text) {
  return text.includes("=");
}

runValidationButton.addEventListener("click", () => {
  clearLog();
  readyMessage.textContent = "";
  goToStep5Button.disabled = true;

  const original = inputQuestion.value.trim();
  if (!original) {
    addLogEntry("Validation failed: the question text is empty.");
    readyMessage.textContent = "Question is not ready for AI processing.";
    readyMessage.style.color = "#d63384";
    return;
  }

  addLogEntry("Loaded confirmed question text.");

  const normalised = normaliseSymbols(original);
  if (normalised !== original) {
    addLogEntry(
      "Normalised mathematical symbols (e.g., × to *, ÷ to /, and spacing).",
    );
  } else {
    addLogEntry("No symbol normalisation was required.");
  }

  if (!hasEquationStructure(normalised)) {
    addLogEntry(
      'Validation failed: expected an equation containing an "=" sign.',
    );
    normalisedExpressionElement.textContent = normalised;
    readyMessage.textContent = "Question is not ready for AI processing.";
    readyMessage.style.color = "#d63384";
    return;
  }

  addLogEntry('Detected an equation structure with an "=" sign.');

  const numberMatches = normalised.match(/[-+]?\d+(?:\.\d+)?/g) || [];
  if (numberMatches.length < 2) {
    addLogEntry(
      "Warning: found fewer than two numeric values; the expression may be incomplete.",
    );
  } else {
    addLogEntry(
      `Found ${numberMatches.length} numeric value(s), suggesting a complete equation.`,
    );
  }

  normalisedExpressionElement.textContent = normalised;
  // Persist the validated, normalised question so that the AI module
  // in Step 5 can operate on the exact same expression the user saw here.
  try {
    window.localStorage.setItem("validatedQuestion", normalised);
  } catch (error) {
    // If storage is unavailable, the system still works with a fallback
    // default question inside the AI module.
  }
  readyMessage.textContent =
    "Validation successful: the question is now ready for AI processing.";
  readyMessage.style.color = "#198754";
  goToStep5Button.disabled = false;
});

goToStep5Button.addEventListener("click", () => {
  if (goToStep5Button.disabled) return;
  window.location.href = "../step-5-ai-solution/step-5-ai-solution.html";
});
