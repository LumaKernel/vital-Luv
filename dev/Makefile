
VIM_PATH ?= vim
NVIM_PATH ?= nvim
vimscript_dir := ./ProfileParser
to_profile != find $(vimscript_dir) -name test_*.vim
profile_dir := ../test/unit/ProfileParser/fixtures/profile
profiled := $(patsubst test_%.vim,%.profile,$(notdir $(to_profile)))
vim_profiled := $(profiled:%=$(profile_dir)/vim_%)
nvim_profiled := $(profiled:%=$(profile_dir)/nvim_%)

.PHONY: all install nothing
all: nothing
install: nothing
nothing:
	echo 'Nothing was done.'

.PHONY: clean
clean:
	-rm -f $(profile_dir)/*.profile

.PHONY: profiles
profiles:  $(vim_profiled) $(nvim_profiled) profiles-replace

$(profile_dir)/vim_%.profile: $(vimscript_dir)/test_%.vim
	$(VIM_PATH) -u ./ProfileParser/runner.vim -i NONE -E -n -N -- $<

.PHONY: profiles-nvim
$(profile_dir)/nvim_%.profile: $(vimscript_dir)/test_%.vim
	$(NVIM_PATH) --clean -u ./ProfileParser/runner.vim -i NONE --headless -n -N -- $<

.PHONY: profiles-vim
profiles-replace: $(vim_profiled) $(nvim_profiled)
	sed -i -e 's/SCRIPT\( \+\).*\/\([^/]\+\.vim\)/SCRIPT\1\/test\/\2/' $(vim_profiled) $(nvim_profiled)
	sed -i -e 's/\( \+\)Defined:\( \+\).*\/\([^/]\+\.vim\)/\1Defined:\2\/test\/original\/some\/..\/\3/' $(vim_profiled) $(nvim_profiled)
