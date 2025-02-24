const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Configure email transport
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "your-email@gmail.com",  // Replace with your email
    pass: "your-app-password"      // Use an App Password (if using Gmail)
  }
});

// Callable function to send an email
exports.sendEmailOnNewField = functions.https.onCall((data, context) => {
  const { documentId, newFields } = data;

  if (!newFields || Object.keys(newFields).length === 0) {
    return { success: false, message: "No new fields detected" };
  }

  const fieldDetails = Object.entries(newFields)
    .map(([key, value]) => `${key}: ${value}`)
    .join("\n");

  const mailOptions = {
    from: "your-email@gmail.com",
    to: "boopalan1428@gmail.com",
    subject: "New Field Added in Firestore",
    text: `A new field was added to document ${documentId}:\n\n${fieldDetails}`
  };

  return transporter.sendMail(mailOptions)
    .then(() => {
      console.log("✅ Email sent successfully!");
      return { success: true };
    })
    .catch(error => {
      console.error("❌ Error sending email:", error);
      return { success: false, message: error.message };
    });
});
