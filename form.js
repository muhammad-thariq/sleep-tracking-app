function createSleepWellTestingForm() {
  // 1. Create the Form and set the title/description
  const form = FormApp.create('SleepWell Usability Testing');
  form.setDescription(
    'Hello, we are from Team TIDO. This is our final project: SleepWell, a sleep ' +
    'tracking app that automatically detects your sleep, analyzes your sleep stages ' +
    'and quality, and wakes you gently with smart alarms. After trying the app, ' +
    'please answer the questions below to help us evaluate its usability.'
  );

  // Optional: Uncomment the next line if you want to automatically collect respondent emails
  // form.setCollectEmail(true);

  // 2. Add Demographic Questions
  form.addMultipleChoiceItem()
      .setTitle('Gender')
      .setChoiceValues(['Male', 'Female'])
      .setRequired(true);

  form.addTextItem()
      .setTitle('Age')
      .setRequired(true);

  form.addTextItem()
      .setTitle('Education Background')
      .setRequired(true);

  // 3. Add the Usability Scale Questions (1 to 5)
  // Adapted System Usability Scale (SUS): odd items are positive, even items are
  // negative, tailored to SleepWell's features.
  const scaleQuestions = [
    "1. I think that I would like to use SleepWell frequently to track my sleep",
    "2. I found SleepWell unnecessarily complex",
    "3. I thought SleepWell was easy to use",
    "4. I think that I would need the support of a technical person to be able to use SleepWell",
    "5. I found the various functions in SleepWell (tracking, analysis, smart alarms) were well integrated",
    "6. I thought there was too much inconsistency in SleepWell",
    "7. I would imagine that most people would learn to use SleepWell very quickly",
    "8. I found SleepWell very cumbersome to use",
    "9. I felt very confident using SleepWell",
    "10. I needed to learn a lot of things before I could get going with SleepWell"
  ];

  // Loop through the array and create a 1-5 scale item for each question
  scaleQuestions.forEach(question => {
    form.addScaleItem()
        .setTitle(question)
        .setBounds(1, 5)
        .setLabels('Strongly disagree', 'Strongly agree')
        .setRequired(true);
  });

  // 4. Add SleepWell-specific feature questions (1 to 5)
  const featureQuestions = [
    "The automatic sleep detection worked the way I expected",
    "The sleep analysis (sleep score, stages, and disturbances) was easy to understand",
    "Setting up and editing smart alarms felt clear and straightforward",
    "Navigating between the tabs (Dashboard, Tracking, Analysis, Alarms, Profile) felt logical and not confusing"
  ];

  featureQuestions.forEach(question => {
    form.addScaleItem()
        .setTitle(question)
        .setBounds(1, 5)
        .setLabels('Strongly disagree', 'Strongly agree')
        .setRequired(true);
  });

  // 5. Add the final open-ended comment section
  form.addParagraphTextItem()
      .setTitle('Other Comments / Suggestions for SleepWell');

  // 6. Output the links to the Execution Log
  Logger.log('Form created successfully!');
  Logger.log('Live Form URL (Send to testers): ' + form.getPublishedUrl());
  Logger.log('Edit Form URL (For Team TIDO): ' + form.getEditUrl());
}
