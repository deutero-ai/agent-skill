# Prototype, screenshot and concept tests

A prototype or concept test is a user research study whose stimulus is an image: a screen, a logo, packaging, a pricing page. It is not a separate skill; build it with the same steps as the rest of `user-research` and use the image question types where the stimulus belongs.

## Check the plan first

`present_images` and `image_upload` need Solo or above. On Hobby both are refused with 403 `upgrade_required`; read `plan.image_questions` from `get_credit_balance` before designing. On Hobby, describe the stimulus in words or link to it in the question text, and say plainly that the participant is reacting to a description.

## Shape of the study

1. **One decision per study.** "Which of these three onboarding screens would you trust with a card number?" is a study. "What do you think of the redesign?" is not.
2. **Ask about the past before the picture.** Open with how they do the task today, so the image is judged against real behaviour and not in a vacuum.
3. **Show with `present_images`** (one to four images, each with a short distinct `label`; see `plan-interview-research/references/question-types.md`). Follow with an open question, not a rating: what they notice first, what they expect to happen next, what they would do.
4. **Ask for their own material with `image_upload`** when the current state matters: a photo of the setup, a screenshot of the screen they actually use.
5. **Randomise nothing you cannot read back.** Keep the label order stable across participants unless you intend to compare position effects, and say so in the study notes.

## Before you spend real participants

Run the study through `simulate-users` with the images attached: the persona sees them, so broken labels ("the second one") and leading wording show up in the transcript. A simulation checks the instrument, never the concept; it is not evidence about real people.
