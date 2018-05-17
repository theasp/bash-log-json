TARGETS=log-json.bash

all: deps $(TARGETS)

clean:
	$(RM) $(TARGETS)

log-json.bash: src/log-json.bash deps/bash-preexec/bash-preexec.sh
	cat $^ > $@
	chmod +x log-json.bash

deps: deps/bash-preexec

deps/bash-preexec:
	git submodule update --init deps/bash-preexec

deps/bash-preexec/bash-preexec.sh: deps/bash-preexec

.PHONY: all deps clean
