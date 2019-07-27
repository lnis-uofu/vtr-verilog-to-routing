#!/bin/bash

source .github/travis/common.sh
set -e

$SPACER

if [ "_${_COVERITY_EMAIL}" == "_" ] ||
[ "_${_COVERITY_URL}" == "_" ] ||
[ "_${_COVERITY_MD5}" == "_" ]
then
  echo "_COVERITY_EMAIL, _COVERITY_URL and _COVERITY_MD5 must be set before using this script"
  exit 1
fi

build_root=${PWD}

##########################
# download coverity tool
start_section "coverity download" "${GREEN}Downloading coverity tool..${NC}"

mkdir -p ${HOME}/coverity
cd ${HOME}/coverity

wget --quiet ${_COVERITY_URL} --post-data="token=${COVERITY_SCAN_TOKEN}&project=Verilog+to+Routing" -O coverity.tar.gz
echo "${_COVERITY_MD5} coverity.tar.gz" | md5sum -c -
tar xzf coverity.tar.gz
rm -f coverity.tar.gz

coverity_dir=$(ls -d cov-analysis-linux64*)
export PATH="${PATH}:${HOME}/coverity/${coverity_dir}/bin"
which cov-build
cov-configure --compiler `which ${CC}`

cd ${build_root}

end_section "coverity download"


$SPACER


#######################
# build with coverity
start_section "coverity.vtr.build" "${GREEN}Building..${NC}"

# make sure we use the compiler
export CCACHE_DISABLE=1

rm -f ${build_root}/CMakeCache.txt
rm -Rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

cmake -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=debug -DVTR_ASSERT_LEVEL=3 -DWITH_BLIFEXPLORER=on ${build_root}
cov-build --dir cov-int make -j$(nproc --all)

end_section "coverity.vtr.build"


$SPACER


#######################
# export to coverity
start_section "coverity.export" "${GREEN}Exporting..${NC}"

tar -czvf vtr_coverity.tar.gz cov-int

curl --form token=${COVERITY_SCAN_TOKEN} \
  --form email=${_COVERITY_EMAIL} \
  --form file=@vtr_coverity.tar.gz\
  --form version="master branch head" \
  --form description="$(git log -1|head -1)" \
  https://scan.coverity.com/builds?project=Verilog+to+Routing


end_section "coverity.export"


$SPACER
