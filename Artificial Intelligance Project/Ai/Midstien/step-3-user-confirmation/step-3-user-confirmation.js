// Step 3: User Confirmation and Editing

const questionText = document.getElementById("questionText");
const confirmButton = document.getElementById("confirmButton");
const confirmStatus = document.getElementById("confirmStatus");
const proceedButton = document.getElementById("proceedButton");

// Use the cleaned OCR question as the starting point.
// This keeps the narrative consistent with Step 2.
const DEFAULT_QUESTION = "";

let isConfirmed = false;

function initialiseQuestion() {
  questionText.value = DEFAULT_QUESTION;
}

function updateConfirmationState(confirmed) {
  isConfirmed = confirmed;
  if (confirmed) {
    confirmStatus.textContent =
      "Question confirmed. You may proceed to validation.";
    confirmStatus.style.color = "#198754";
    proceedButton.disabled = false;
  } else {
    confirmStatus.textContent =
      "Please review the question and confirm it before continuing.";
    confirmStatus.style.color = "#d63384";
    proceedButton.disabled = true;
  }
}

confirmButton.addEventListener("click", () => {
  const trimmed = questionText.value.trim();
  if (!trimmed) {
    updateConfirmationState(false);
    return;
  }
  updateConfirmationState(true);
});

questionText.addEventListener("input", () => {
  // Any edit resets confirmation until the user explicitly confirms again.
  if (isConfirmed) {
    updateConfirmationState(false);
  }
});

proceedButton.addEventListener("click", () => {
  if (!isConfirmed) return;
  window.location.href =
    "../step-4-question-validation/step-4-question-validation.html";
});

initialiseQuestion();
