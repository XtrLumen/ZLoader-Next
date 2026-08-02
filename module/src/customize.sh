##VARIABLE##
#PUBLIC#
SKIPUNZIP=1
#CHECK ENVIRONMENT#
PLATFORM=$(getprop ro.hardware)
RELEASE=$(grep_get_prop ro.build.version.release)
MIN_RELEASE=12
KERNEL_VER=$(getprop ro.kernel.version)
KERNEL_VER_INT=$(echo ${KERNEL_VER} | tr '.' ' ' | xargs printf '%02d')
MIN_KERNEL_VER_INT=510
#PRINT INFORMATION#
MODULE_VER=$(grep_prop version "${TMPDIR}/module.prop")
#EXTRACT MODULE FILES#
FILES="
bin/*
lib/*
module.prop
post-fs-data.sh
sepolicy.rule
"
##END##

##FUNCTIONS##
separator_print() {
    ui_print "***********************************************"
}
separator_abort() {
    abort "***********************************************"
}
abort_verify() {
    separator_print
    ui_print "! $@"
    ui_print "! This zip may be corrupted, please try downloading again"
    separator_abort
}
##END##

##PRE PROCESS##
#CHECK INTEGRITY#
unzip -o "${ZIPFILE}" 'verify.sh' -d "${TMPDIR}" >/dev/null
[ -f "${TMPDIR}/verify.sh" ] || abort_verify "Unable to extract verify.sh"
source "${TMPDIR}/verify.sh"
#CHECK ENVIRONMENT#
[ ${BOOTMODE} ] || {
    separator_print
    ui_print "! Install from recovery is not supported"
    ui_print "! Please install from KernelSU, APatch or Magisk app"
    separator_abort
}
[ "${PLATFORM}" = "qcom" ] || {
    separator_print
    ui_print "! Unsupported platform: ${PLATFORM}"
    ui_print "! Supported platform is qcom"
    separator_abort
}
[ ${RELEASE} -lt ${MIN_RELEASE} ] && {
    separator_print
    ui_print "! Unsupported android version: ${RELEASE}"
    ui_print "! Minimal supported android version is ${MIN_RELEASE}"
    separator_abort
}
[ ${KERNEL_VER_INT} -lt ${MIN_KERNEL_VER_INT} ] && {
    separator_print
    ui_print "! Unsupported kernel version: ${KERNEL_VER}"
    ui_print "! Mimimal supported kernel version is ${MIN_KERNEL_VER_INT}"
    separator_abort
}
#PRINT INFORMATION#
if [ ${KSU} ]
then
    ui_print "- KernelSU version code: ${KSU_KERNEL_VER_CODE}(kernel) ${KSU_VER_CODE}(ksud)"
    ui_print "- KernelSU version: ${KSU_VER}"
elif [ ${APATCH} ]
then
    ui_print "- APatch version code: ${APATCH_VER_CODE}"
    ui_print "- APatch version: ${APATCH_VER}"
elif [ ${MAGISK_VER} ]
then
    ui_print "- Magisk version code: ${MAGISK_VER_CODE}"
    ui_print "- Magisk version: ${MAGISK_VER}"
fi
ui_print "- Install module Zloader-Next ${MODULE_VER}"
##END##

##EXTRACT MODULE FILES##
ui_print "- Extracting module files"
for FILE in ${FILES}
do
    extract "${ZIPFILE}" "${FILE}" "${MODPATH}"
done
##END##

##POST PROCESS##
ui_print "- Setting permission"
chcon u:object_r:system_file:s0 "${MODPATH}/lib/libloader.so"
chmod +x "${MODPATH}/bin/zloader"
##END##

ui_print "- Install Done"