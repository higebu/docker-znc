#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $0 ZNC_USER ZNC_PASS"
	exit 1
fi

ZNC_USER=$1
ZNC_PASS=$2
ZNC_CHANS=$3

IFS=, eval 'chans_arr=($ZNC_CHANS)'
if [ ${#chans_arr[@]} -gt 0 ]; then
  chans=$(for c in "${chans_arr[@]}"; do
    echo "	<Chan $c>"
    echo "	</Chan>"
  done)
fi

# Options.
DATADIR="/home/znc"

# Get znc-push
if [ ! -d "${DATADIR}/modules" ]; then
  mkdir -p "${DATADIR}/modules"
  cd "${DATADIR}/modules"
  wget https://raw.github.com/jreese/znc-push/master/push.cpp
  cd "$cwd"
fi

# Build modules from source.
if [ -d "${DATADIR}/modules" ]; then
  # Store current directory.
  cwd="$(pwd)"

  # Find module sources.
  modules=$(find "${DATADIR}/modules" -name "*.cpp")

  # Build modules.
  for module in $modules; do
    cd "$(dirname "$module")"
    znc-buildmod "$module"
  done

  # Go back to original directory.
  cd "$cwd"
fi

# Create ZNC Pass
ZNC_SALT="$(dd if=/dev/urandom bs=16c count=1 | md5sum | awk '{print $1}')"
ZNC_HASH="sha256#$(echo -n ${ZNC_PASS}${ZNC_SALT} | sha256sum | awk '{print $1'})#${ZNC_SALT}#"

# Create default config if it doesn't exist
if [ ! -f "${DATADIR}/configs/znc.conf" ]; then
mkdir -p "${DATADIR}/configs"
cat<<EOF > ${DATADIR}/configs/znc.conf
<Listener l>
	Port = 6667
	IPv4 = true
	IPv6 = false
	SSL = false
</Listener>

LoadModule = webadmin
LoadModule = lastseen

<User $ZNC_USER>
	Pass       = $ZNC_HASH
	Admin      = true
	Nick       = $ZNC_USER
	AltNick    = _$ZNC_USER
	Ident      = $ZNC_USER
	RealName   = $ZNC_USER
	Buffer     = 200
	KeepBuffer = false
	ChanModes  = +stn
	MaxJoins   = 1

	LoadModule = admin
	LoadModule = awaynick
	LoadModule = keepnick
	LoadModule = kickrejoin
	LoadModule = log
	LoadModule = nickserv
	LoadModule = simple_away

	Server     = irc.freenode.net 6667

$chans
</User>
EOF

fi

chown -R znc:znc "$DATADIR"

# Start ZNC.
exec sudo -u znc znc --foreground --datadir="$DATADIR"
