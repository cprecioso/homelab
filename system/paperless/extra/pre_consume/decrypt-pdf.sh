#!/usr/bin/env bash

set -euxo pipefail

# Paperless envs:
# DOCUMENT_SOURCE_PATH	Original path of the consumed document
# DOCUMENT_WORKING_PATH	Path to a copy of the original that consumption will work on
# TASK_ID								UUID of the task used to process the new document (if any)

# Custom envs:
# DECRYPTION_PASSWORDS_FILE	Path to a newline-separated list of passwords to try for decryption

if ! qpdf --is-encrypted "$DOCUMENT_SOURCE_PATH"; then
	echo "PDF is not encrypted, no decryption needed." >&2
	exit 0
fi
echo "PDF is encrypted, attempting decryption..." >&2

if [ -z "${DECRYPTION_PASSWORDS_FILE:-}" ]; then
	echo "No DECRYPTION_PASSWORDS_FILE provided" >&2
	exit 0
fi

if [ ! -f "$DECRYPTION_PASSWORDS_FILE" ]; then
	echo "DECRYPTION_PASSWORDS_FILE '$DECRYPTION_PASSWORDS_FILE' does not exist or is not a file" >&2
	exit 1
fi
echo "Using DECRYPTION_PASSWORDS_FILE: '$DECRYPTION_PASSWORDS_FILE'" >&2

while read -r password; do
	if qpdf --requires-password --password="$password" "$DOCUMENT_SOURCE_PATH"; then
		# qpdf --requires-password returns 0 if the password is incorrect :shrug:
		# so we try the next one
		continue
	fi

	qpdf --password="$password" --decrypt "$DOCUMENT_SOURCE_PATH" "$DOCUMENT_WORKING_PATH"
	echo "Successfully decrypted PDF with provided password." >&2
	exit 0
done <"$DECRYPTION_PASSWORDS_FILE"

echo "Failed to decrypt PDF with any provided password." >&2
exit 1
