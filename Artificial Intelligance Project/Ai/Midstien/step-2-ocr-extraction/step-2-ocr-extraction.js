// Step 2: OCR Extraction (simulated)

const runOcrButton = document.getElementById("runOcrButton");
const rawOcrElement = document.getElementById("rawOcr");
const cleanOcrElement = document.getElementById("cleanOcr");
const confidenceValue = document.getElementById("confidenceValue");
const confidenceFill = document.getElementById("confidenceFill");
const confidenceMessage = document.getElementById("confidenceMessage");

// For this demonstration we use a single sample question.
// A real OCR system would analyse the actual uploaded image.
const SAMPLE_RAW_OCR = "";
const SAMPLE_CLEAN_OCR = "";

function simulateOcrConfidence(rawText, cleanText) {
  // Very simple heuristic: fewer non-alphanumeric characters and more
  // similarity between raw and clean text leads to higher confidence.
  const rawLength = rawText.length || 1;
  const diffCount =
    Math.abs(rawText.length - cleanText.length) +
    rawText.split("").filter((char, index) => cleanText[index] !== char).length;

  const normalisedDiff = Math.min(diffCount / rawLength, 1);
  const score = 1 - normalisedDiff * 0.6; // keep it in a realistic range
  return Math.max(0.4, Math.min(score, 0.95));
}

function updateConfidenceDisplay(score) {
  const percentage = Math.round(score * 100);
  confidenceValue.textContent = `${percentage} %`;
  confidenceFill.style.width = `${percentage}%`;

  if (score < 0.7) {
    confidenceMessage.textContent =
      "Warning: OCR confidence is relatively low. A human should carefully review the extracted question.";
    confidenceMessage.style.color = "#d63384";
  } else if (score < 0.85) {
    confidenceMessage.textContent =
      "Confidence is moderate. User confirmation is strongly recommended before solving the question.";
    confidenceMessage.style.color = "#fd7e14";
  } else {
    confidenceMessage.textContent =
      "Confidence is high, but user confirmation is still useful to catch subtle mathematical errors.";
    confidenceMessage.style.color = "#198754";
  }
}

runOcrButton.addEventListener("click", () => {
  rawOcrElement.textContent = SAMPLE_RAW_OCR;
  cleanOcrElement.textContent = SAMPLE_CLEAN_OCR;

  const score = simulateOcrConfidence(SAMPLE_RAW_OCR, SAMPLE_CLEAN_OCR);
  updateConfidenceDisplay(score);
});
