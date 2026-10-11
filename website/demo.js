const answers = document.querySelectorAll('[data-answer]');
const message = document.querySelector('#demo-result');
for (const answer of answers) {
  answer.addEventListener('click', () => {
    const correct = answer.dataset.answer === '24';
    message.textContent = correct ? 'Ügyes vagy! 6 × 4 = 24. Egy lépéssel közelebb a következő kutyushoz!' : 'Majdnem! Próbáld újra: 6 + 6 + 6 + 6 = ?';
    for (const button of answers) {
      button.classList.remove('correct', 'incorrect');
      button.setAttribute('aria-pressed', 'false');
    }
    answer.classList.add(correct ? 'correct' : 'incorrect');
    answer.setAttribute('aria-pressed', 'true');
  });
}
