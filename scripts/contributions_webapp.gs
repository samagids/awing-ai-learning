/**
 * Awing AI Learning — Contributions Web App (Google Apps Script)
 *
 * Receives user-submitted word corrections, pronunciation recordings,
 * and new content. Stores in Google Sheet + Drive folder, emails the
 * developer on each new submission.
 *
 * SETUP:
 * 1. Go to https://script.google.com, create a new project
 * 2. Paste this script into Code.gs
 * 3. Run setupContributions() once
 * 4. Deploy > New deployment > Web app
 *    - Execute as: Me (samagids@gmail.com)
 *    - Who has access: Anyone
 * 5. Copy the web app URL into:
 *    lib/services/contribution_service.dart → _submitUrl AND _contentVersionUrl
 *
 * This creates:
 * - "Awing Contributions" Google Sheet (with Submissions + Approved + Content tabs)
 * - "Awing Audio Recordings" Google Drive folder (for user audio uploads)
 */

var SHEET_NAME = 'Awing Contributions';
var AUDIO_FOLDER_NAME = 'Awing Audio Recordings';
var DEVELOPER_EMAIL = 'samagids@gmail.com';

/**
 * Run once to create Sheet + Drive folder.
 */
function setupContributions() {
  // Create the Sheet
  var ss = SpreadsheetApp.create(SHEET_NAME);

  // Submissions tab
  var submissions = ss.getSheetByName('Sheet1');
  submissions.setName('Submissions');
  submissions.getRange(1, 1, 1, 13).setValues([[
    'ID', 'Timestamp', 'Profile Name', 'Type', 'Target Word',
    'Correction', 'English', 'Category', 'Notes', 'Audio File',
    'Status', 'Review Notes', 'Reviewed At'
  ]]);
  submissions.setFrozenRows(1);
  submissions.getRange(1, 1, 1, 13).setFontWeight('bold');

  // Approved tab — content that's been pushed to users
  var approved = ss.insertSheet('Approved');
  approved.getRange(1, 1, 1, 8).setValues([[
    'ID', 'Type', 'Target Word', 'Correction', 'English',
    'Category', 'Approved At', 'Content Version'
  ]]);
  approved.setFrozenRows(1);
  approved.getRange(1, 1, 1, 8).setFontWeight('bold');

  // Content Version tab — tracks what version all users should be at
  var version = ss.insertSheet('ContentVersion');
  version.getRange(1, 1, 1, 2).setValues([['Version', 'Last Updated']]);
  version.getRange(2, 1, 1, 2).setValues([[0, new Date().toISOString()]]);
  version.setFrozenRows(1);
  version.getRange(1, 1, 1, 2).setFontWeight('bold');

  // Create audio folder
  var folder = DriveApp.createFolder(AUDIO_FOLDER_NAME);

  Logger.log('Sheet: ' + ss.getUrl());
  Logger.log('Audio folder: ' + folder.getUrl());
  Logger.log('Setup complete! Deploy as web app next.');
}

/**
 * Handle POST requests from the Flutter app.
 */
function doPost(e) {
  try {
    var payload = JSON.parse(e.postData.contents);
    var action = payload.action || 'submit';

    switch (action) {
      case 'submit':
        return handleSubmission(payload);
      case 'fetch_pending':
        return handleFetchPending();
      case 'fetch_all':
        return handleFetchAll();
      case 'approve':
        return handleApproval(payload);
      case 'reject':
        return handleRejection(payload);
      case 'check_version':
        return handleVersionCheck(payload);
      case 'fetch_audio':
        return handleFetchAudio(payload);
      default:
        return jsonResponse({ status: 'error', message: 'Unknown action' });
    }
  } catch (err) {
    return jsonResponse({ status: 'error', message: err.toString() });
  }
}

/**
 * Handle a new user submission.
 */
function handleSubmission(payload) {
  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');

  // Save audio file to Drive if included
  var audioFileUrl = '';
  if (payload.audioBase64) {
    try {
      var folder = getAudioFolder();
      var decoded = Utilities.base64Decode(payload.audioBase64);
      var blob = Utilities.newBlob(decoded, 'audio/m4a', payload.id + '.m4a');
      var file = folder.createFile(blob);
      file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
      audioFileUrl = file.getUrl();
    } catch (audioErr) {
      Logger.log('Audio upload error: ' + audioErr.toString());
    }
  }

  // Append row to Submissions sheet
  submissions.appendRow([
    payload.id || '',
    new Date().toISOString(),
    payload.profileName || 'Anonymous',
    payload.type || '',
    payload.targetWord || '',
    payload.correction || '',
    payload.englishMeaning || '',
    payload.category || '',
    payload.notes || '',
    audioFileUrl,
    'pending',
    '',
    ''
  ]);

  // Send email notification to developer
  try {
    var typeLabel = {
      'spellingCorrection': 'Spelling Fix',
      'pronunciationFix': 'Pronunciation Recording',
      'newWord': 'New Word',
      'newSentence': 'New Sentence',
      'newPhrase': 'New Phrase',
      'generalFeedback': 'General Feedback'
    }[payload.type] || payload.type;

    var subject = '[Awing] New ' + typeLabel + ': "' + (payload.targetWord || '?') + '"';

    var body = 'A user submitted a contribution:\n\n' +
      'Type: ' + typeLabel + '\n' +
      'From: ' + (payload.profileName || 'Anonymous') + '\n' +
      'Word: ' + (payload.targetWord || '') + '\n' +
      'Correction: ' + (payload.correction || '(none)') + '\n' +
      'English: ' + (payload.englishMeaning || '(none)') + '\n' +
      'Category: ' + (payload.category || '(none)') + '\n' +
      'Notes: ' + (payload.notes || '(none)') + '\n';

    if (audioFileUrl) {
      body += '\nAudio recording: ' + audioFileUrl + '\n';
    }

    body += '\nOpen the Awing app > Developer Mode > Review to approve or reject.\n';
    body += '\nSheet: ' + ss.getUrl();

    MailApp.sendEmail(DEVELOPER_EMAIL, subject, body);
  } catch (emailErr) {
    Logger.log('Email error: ' + emailErr.toString());
  }

  return jsonResponse({
    status: 'ok',
    id: payload.id,
    audioUrl: audioFileUrl || null
  });
}

/**
 * Fetch all pending submissions (for developer review).
 */
function handleFetchPending() {
  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');
  var data = submissions.getDataRange().getValues();
  var contributions = [];

  // Skip header row
  for (var i = 1; i < data.length; i++) {
    var row = data[i];
    if (row[10] === 'pending') { // Status column
      contributions.push({
        id: row[0],
        submittedAt: row[1],
        profileName: row[2],
        type: row[3],
        targetWord: row[4],
        correction: row[5],
        englishMeaning: row[6],
        category: row[7],
        notes: row[8],
        audioUrl: row[9],
        status: row[10],
        reviewNotes: row[11],
        reviewedAt: row[12]
      });
    }
  }

  return jsonResponse({ status: 'ok', contributions: contributions });
}

/**
 * Fetch ALL submissions (pending, approved, rejected) — used by Developer
 * Mode dashboard to show a live count of contributions across all devices,
 * not just what's been imported into the local SharedPreferences.
 *
 * The Developer Mode Review tab calls this on open + every 30 seconds so
 * the developer sees new contributions arrive without restarting the app.
 */
function handleFetchAll() {
  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');
  var data = submissions.getDataRange().getValues();
  var contributions = [];

  // Skip header row
  for (var i = 1; i < data.length; i++) {
    var row = data[i];
    // Skip blank rows (no id)
    if (!row[0]) continue;
    contributions.push({
      id: row[0],
      submittedAt: row[1] ? new Date(row[1]).toISOString() : null,
      profileName: row[2],
      type: row[3],
      targetWord: row[4],
      correction: row[5],
      englishMeaning: row[6],
      category: row[7],
      notes: row[8],
      audioUrl: row[9],
      status: row[10] || 'pending',
      reviewNotes: row[11],
      reviewedAt: row[12] ? new Date(row[12]).toISOString() : null
    });
  }

  return jsonResponse({ status: 'ok', contributions: contributions });
}

/**
 * Approve a contribution and bump content version.
 *
 * IDEMPOTENT: if this `id` is already in the Approved sheet, return the
 * existing version without appending a new row or sending another email.
 * This is required because the client's offline-queue retry may resend
 * an approval that the server already processed (e.g. when the client's
 * redirect-follow times out before it sees the success response). Without
 * this check, every retry appends a duplicate Approved row with a higher
 * version, which `handleVersionCheck` then returns as two separate updates
 * for the same contribution.
 */
function handleApproval(payload) {
  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');
  var approved = ss.getSheetByName('Approved');
  var versionSheet = ss.getSheetByName('ContentVersion');

  // Idempotency check: already approved?
  var approvedData = approved.getDataRange().getValues();
  for (var j = 1; j < approvedData.length; j++) {
    if (approvedData[j][0] === payload.id) {
      // Already approved — return the existing version, do not append.
      var existingVersion = approvedData[j][7];
      return jsonResponse({
        status: 'ok',
        version: existingVersion,
        alreadyApproved: true
      });
    }
  }

  // Find and update the submission row
  var data = submissions.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] === payload.id) {
      submissions.getRange(i + 1, 11).setValue('approved');
      submissions.getRange(i + 1, 12).setValue(payload.reviewNotes || '');
      submissions.getRange(i + 1, 13).setValue(new Date().toISOString());

      // Add to Approved sheet
      var currentVersion = versionSheet.getRange(2, 1).getValue() || 0;
      var newVersion = currentVersion + 1;

      approved.appendRow([
        payload.id,
        payload.type,
        payload.targetWord,
        payload.correction,
        payload.englishMeaning || '',
        payload.category || '',
        new Date().toISOString(),
        newVersion
      ]);

      // Bump version
      versionSheet.getRange(2, 1).setValue(newVersion);
      versionSheet.getRange(2, 2).setValue(new Date().toISOString());

      // Email notification
      try {
        MailApp.sendEmail(
          DEVELOPER_EMAIL,
          '[Awing] Approved: "' + (payload.targetWord || '') + '" (v' + newVersion + ')',
          'Content version ' + newVersion + ' published.\n' +
          'Word: ' + (payload.targetWord || '') + ' → ' + (payload.correction || '') + '\n' +
          'All users will receive this update on next app open.'
        );
      } catch (_) {}

      return jsonResponse({ status: 'ok', version: newVersion });
    }
  }

  // Not in Submissions — but we already confirmed it's not in Approved
  // above. This means the id really is unknown.
  return jsonResponse({ status: 'error', message: 'Contribution not found' });
}

/**
 * Reject a contribution.
 */
function handleRejection(payload) {
  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');
  var data = submissions.getDataRange().getValues();

  for (var i = 1; i < data.length; i++) {
    if (data[i][0] === payload.id) {
      submissions.getRange(i + 1, 11).setValue('rejected');
      submissions.getRange(i + 1, 12).setValue(payload.reason || '');
      submissions.getRange(i + 1, 13).setValue(new Date().toISOString());
      return jsonResponse({ status: 'ok' });
    }
  }

  return jsonResponse({ status: 'error', message: 'Contribution not found' });
}

/**
 * Check content version and return updates if newer version exists.
 *
 * Cross-references the Submissions sheet at query time to return the
 * audioUrl for pronunciationFix contributions. This avoids needing to
 * migrate the Approved sheet schema when we added audio support — the
 * audio URL lives in Submissions (column 10), keyed by contribution id.
 */
function handleVersionCheck(payload) {
  var ss = getSheet();
  var versionSheet = ss.getSheetByName('ContentVersion');
  var currentVersion = versionSheet.getRange(2, 1).getValue() || 0;
  var clientVersion = payload.currentVersion || 0;

  if (currentVersion <= clientVersion) {
    return jsonResponse({ status: 'ok', version: currentVersion, updates: [] });
  }

  // Build id → audioUrl map from Submissions sheet (column 10 is 'Audio File')
  var submissions = ss.getSheetByName('Submissions');
  var subData = submissions.getDataRange().getValues();
  var audioById = {};
  for (var k = 1; k < subData.length; k++) {
    var sid = subData[k][0];
    var url = subData[k][9];
    if (sid && url) audioById[sid] = url;
  }

  // Fetch approved items newer than client version
  var approved = ss.getSheetByName('Approved');
  var data = approved.getDataRange().getValues();
  var updates = [];

  for (var i = 1; i < data.length; i++) {
    var itemVersion = data[i][7]; // Content Version column
    if (itemVersion > clientVersion) {
      updates.push({
        id: data[i][0],
        type: data[i][1],
        targetWord: data[i][2],
        correction: data[i][3],
        englishMeaning: data[i][4],
        category: data[i][5],
        approvedAt: data[i][6],
        version: data[i][7],
        audioUrl: audioById[data[i][0]] || null
      });
    }
  }

  return jsonResponse({
    status: 'ok',
    version: currentVersion,
    updates: updates
  });
}

/**
 * Return audioUrl for each contribution id passed in.
 * Payload: { action: 'fetch_audio', ids: ['id1', 'id2', ...] }
 * Used by apply_contributions.py --refetch-audio to recover audio for
 * contributions that were approved BEFORE handleVersionCheck learned to
 * include audioUrl (i.e. before this file was redeployed).
 */
function handleFetchAudio(payload) {
  var ids = payload.ids || [];
  if (!Array.isArray(ids) || ids.length === 0) {
    return jsonResponse({ status: 'ok', audio: {} });
  }

  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');
  var subData = submissions.getDataRange().getValues();

  // Column 0 is id, column 9 is audio URL.
  var wanted = {};
  for (var j = 0; j < ids.length; j++) {
    wanted[ids[j]] = true;
  }

  var audio = {};
  for (var k = 1; k < subData.length; k++) {
    var sid = subData[k][0];
    var url = subData[k][9];
    if (sid && url && wanted[sid]) {
      audio[sid] = url;
    }
  }

  return jsonResponse({ status: 'ok', audio: audio });
}

// ==================== Helpers ====================

function getSheet() {
  var files = DriveApp.getFilesByName(SHEET_NAME);
  while (files.hasNext()) {
    var file = files.next();
    // Only open actual spreadsheets, not Apps Script projects with the same name
    if (file.getMimeType() === 'application/vnd.google-apps.spreadsheet') {
      return SpreadsheetApp.open(file);
    }
  }
  throw new Error('Sheet "' + SHEET_NAME + '" not found. Run setupContributions() first.');
}

function getAudioFolder() {
  var folders = DriveApp.getFoldersByName(AUDIO_FOLDER_NAME);
  if (folders.hasNext()) {
    return folders.next();
  }
  return DriveApp.createFolder(AUDIO_FOLDER_NAME);
}

function jsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

function doGet(e) {
  return jsonResponse({
    status: 'ok',
    service: 'Awing Contributions',
    timestamp: new Date().toISOString()
  });
}
