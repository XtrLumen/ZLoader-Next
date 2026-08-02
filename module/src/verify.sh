TMPDIR_FOR_VERIFY="${TMPDIR}/.vunzip"
mkdir -p "${TMPDIR_FOR_VERIFY}"

extract() {
    unpack() {
        local zip=${1}
        local file=${2}
        local dir=${3}
        local args=${4}
        unzip -o "${zip}" "${file}" -d "${dir}" >/dev/null 2>&1
        file_path="${dir}/${file}"
        if [ -f "${file_path}" ]
        then
            unzip -o "${zip}" "MANIFEST/${file}.sha256" -d "${TMPDIR_FOR_VERIFY}" >/dev/null 2>&1
            hash_path="${TMPDIR_FOR_VERIFY}/MANIFEST/${file}.sha256"
            if [ -f "${hash_path}" ]
            then
                (echo "$(cat "${hash_path}")  ${file_path}" | sha3sum -a 256 -c -s -) || abort_verify "Failed to verify ${file}"
            elif [[ ! "${args}" == *"-s"* ]]
            then
                abort_verify "${file}.sha256 not exists"
            fi
        else
            abort_verify "${file} not exists"
        fi
        [[ "${args}" == *"-q"* ]] || ui_print "- Verified ${file}"
    }
    if [[ "${2}" == */\* ]]
    then
        for file in $(unzip -l "${1}" "${2}" 2>/dev/null | awk 'NR>3 {print $4}' | grep -v '/$' | grep -v '^$')
        do
            unpack "${1}" "${file}" "${3}" "${4} ${5}"
        done
    else
        unpack "${@}"
    fi
}

extract "${ZIPFILE}" 'META-INF/com/google/android/*' "${TMPDIR_FOR_VERIFY}" -q -s
extract "${ZIPFILE}" 'verify.sh' "${TMPDIR_FOR_VERIFY}" -q
extract "${ZIPFILE}" 'customize.sh' "${TMPDIR_FOR_VERIFY}" -q