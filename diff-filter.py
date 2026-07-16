import re
import sys


def normalize(text):
    return re.sub(r"\s+", "", text)


with open(sys.argv[1], "r") as f:
    diff_text = f.read()

files = diff_text.split("diff --git")
for file_diff in files[1:]:
    file_diff = "diff --git" + file_diff
    lines = file_diff.split("\n")
    header = []
    hunks = []
    current_hunk = []
    in_hunk = False

    for line in lines:
        if line.startswith("@@ "):
            if current_hunk:
                hunks.append(current_hunk)
            current_hunk = [line]
            in_hunk = True
        elif in_hunk:
            current_hunk.append(line)
        else:
            header.append(line)

    if current_hunk:
        hunks.append(current_hunk)

    file_name = header[0].split(" b/")[-1] if len(header) > 0 else "Unknown"

    # Check hunks
    real_hunks = []
    for hunk in hunks:
        adds = []
        subs = []
        for line in hunk[1:]:
            if line.startswith("+") and not line.startswith("+++"):
                adds.append(line[1:])
            elif line.startswith("-") and not line.startswith("---"):
                subs.append(line[1:])

        # compare normalized strings
        adds_norm = normalize("".join(adds))
        subs_norm = normalize("".join(subs))

        if adds_norm != subs_norm:
            real_hunks.append(hunk)

    if real_hunks:
        print("\n".join(header))
        for hunk in real_hunks:
            print("\n".join(hunk))
