
VIM_PATH ?= vim
NVIM_PATH ?= nvim

.PHONY: all install nothing
all: nothing
install: nothing
nothing:
	echo 'Nothing was done.'

.PHONY: clean
clean:
	-rm -f ../test/unit/ProfileParser/fixtures/*.profile

.PHONY: profiles
profiles: profiles-vim profiles-nvim

.PHONY: profiles-vim
profiles-vim:
	find ./ProfileParser -name test_*.vim -exec $(VIM_PATH) -u ./ProfileParser/runner.vim -i NONE -E -n -N {} \;

.PHONY: profiles-nvim
profiles-nvim:
	find ./ProfileParser -name test_*.vim -exec $(NVIM_PATH) --clean -u ./ProfileParser/runner.vim -i NONE --noplugin --headless -n -N -- {} \;
