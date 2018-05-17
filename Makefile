TARGETS=log-json.bash

all: $(TARGETS)

clean:
	$(RM) $(TARGETS)

log-json.bash: src/log-json.bash deps/bash-preexec/bash-preexec.sh
	cat $^ > $@
	chmod +x log-json.bash

deps/bash-preexec/bash-preexec.sh:
	git submodule update deps/bash-preexec


.PHONY: all clean
