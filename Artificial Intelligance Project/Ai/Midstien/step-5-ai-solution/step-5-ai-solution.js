// Step 5: AI Based Step-by-Step Solution

const solveButton = document.getElementById("solveButton");
const apiStatus = document.getElementById("apiStatus");
const solutionStepsElement = document.getElementById("solutionSteps");
const finalAnswerContainer = document.getElementById("finalAnswerContainer");
const validatedQuestionElement = document.getElementById("validatedQuestion");

function clearSolution() {
  while (solutionStepsElement.firstChild) {
    solutionStepsElement.removeChild(solutionStepsElement.firstChild);
  }
  finalAnswerContainer.textContent = "";
}

function getValidatedQuestionText() {
  // Prefer the expression saved during validation; fall back to
  // a simple built-in example if none is available.
  try {
    const stored = window.localStorage.getItem("validatedQuestion");
    if (stored && stored.trim()) {
      return stored.trim();
    }
  } catch (error) {
    // Ignore storage errors and use the default example.
  }
  return "";
}

function extractEquationFromQuestion(questionText) {
  const trimmed = questionText.trim();
  const colonIndex = trimmed.indexOf(":");
  if (colonIndex === -1) {
    return trimmed;
  }
  return trimmed.slice(colonIndex + 1).trim();
}

function parseLinearEquation(equation) {
  const compact = equation.replace(/\s+/g, "");

  // Support equations of the form ax + b = c where a, b, c are numbers.
  const match = compact.match(
    /^([+-]?\d*\.?\d*)x([+-]\d*\.?\d*)?=([+-]?\d*\.?\d*)$/,
  );

  if (!match) {
    return null;
  }

  const aRaw = match[1];
  const bRaw = match[2] || "+0";
  const cRaw = match[3];

  function parseCoefficient(raw, defaultMagnitude) {
    if (raw === "" || raw === "+") return defaultMagnitude;
    if (raw === "-") return -defaultMagnitude;
    const value = parseFloat(raw);
    return Number.isFinite(value) ? value : defaultMagnitude;
  }

  const a = parseCoefficient(aRaw, 1);
  const b = parseFloat(bRaw);
  const c = parseFloat(cRaw);

  if (!Number.isFinite(a) || !Number.isFinite(b) || !Number.isFinite(c)) {
    return null;
  }
  if (a === 0) {
    return null;
  }

  const xRaw = (c - b) / a;
  const x = Number.isInteger(xRaw) ? xRaw : parseFloat(xRaw.toFixed(3));

  return { a, b, c, x };
}

function buildSolution(questionText) {
  const equation = extractEquationFromQuestion(questionText);
  const parsed = parseLinearEquation(equation);

  if (!parsed) {
    return {
      steps: [
        `Received question: ${questionText}`,
        "This demo solver currently supports linear equations of the form ax + b = c with a single variable x.",
        "The provided expression does not match this pattern, so a numeric solution is not generated.",
      ],
      finalAnswer:
        "No numeric solution generated (unsupported equation format for this demo).",
    };
  }

  const { a, b, c, x } = parsed;
  const rhsAfterSubtraction = c - b;

  const steps = [];
  const signForB = b >= 0 ? "+" : "-";
  const absB = Math.abs(b);
  const prettyEquation =
    b === 0 ? `${a}x = ${c}` : `${a}x ${signForB} ${absB} = ${c}`;

  steps.push(`Start from the normalised equation: ${prettyEquation}.`);

  if (b !== 0) {
    steps.push(
      `Subtract ${b} from both sides: ${a}x ${signForB} ${absB} − ${b} = ${c} − ${b}, which simplifies to ${a}x = ${rhsAfterSubtraction}.`,
    );
  }

  steps.push(
    `Divide both sides by ${a} to isolate x: (${a}x) / ${a} = ${rhsAfterSubtraction} / ${a}, giving x = ${x}.`,
  );
  steps.push(`Therefore, the value of x that satisfies the equation is ${x}.`);

  const finalAnswer = Number.isInteger(x)
    ? `Final answer: x = ${x}`
    : `Final answer: x = ${x} (approximately)`;

  return { steps, finalAnswer };
}

function renderSolution(questionText) {
  clearSolution();
  const { steps, finalAnswer } = buildSolution(questionText);

  steps.forEach((stepText) => {
    const li = document.createElement("li");
    li.textContent = stepText;
    solutionStepsElement.appendChild(li);
  });

  finalAnswerContainer.textContent = finalAnswer;
}

// Initialise the displayed question from validation or fall back to default.
const initialQuestion = getValidatedQuestionText();
validatedQuestionElement.textContent = initialQuestion;

solveButton.addEventListener("click", () => {
  clearSolution();
  apiStatus.textContent = "Solving the validated question...";
  apiStatus.style.color = "#0b5ed7";

  setTimeout(() => {
    apiStatus.textContent = "Solution generated with transparent reasoning.";
    apiStatus.style.color = "#198754";
    renderSolution(validatedQuestionElement.textContent.trim());
  }, 700);
});
