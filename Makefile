

tex-symbols=docs/symbols.tex
duckietown-software=duckietown
RUNBOOK=misc/run-book.sh

all:
	# make update-software
	ONLY_FOR_REFS=1 make books
	make books
	make summaries

summaries:
	cp misc/frames.html duckuments-dist/index.html
	. deploy/bin/activate && python misc/make_index.py duckuments-dist/summary.html duckuments-dist/all_crossref.html

realclean: clean
	rm -rf duckuments-dist

.PHONY: checks check-duckietown-software check-programs

.PHONY: builds install update-software

dependencies-ubuntu16:
	sudo apt install -y \
		libxml2-dev \
		libxslt1-dev \
		libffi6\
		libffi-dev\
		python-dev\
		python-numpy\
		python-matplotlib\
		virtualenv\
		bibtex2html\
		pdftk\
		imagemagick\
		python-dev\
		libmysqlclient-dev

install-ubuntu16:
	virtualenv --system-site-packages --no-site-packages deploy
	$(MAKE) install-fonts
	$(MAKE) update-software

install-fonts:
	cp -R misc/fonts /usr/share/fonts/my-fonts
	fc-cache -f -v


update-software:
	git submodule sync --recursive
	git submodule update --init --recursive
	. deploy/bin/activate && pip install -r mcdp/requirements.txt && pip install numpy matplotlib MySQL-python

	. deploy/bin/activate && cd mcdp && python setup.py develop

builds:
	cp misc/jquery* builds/
	python -m mcdp_docs.sync_from_circle duckietown duckuments builds builds/duckuments.html

db.related.yaml:
	. deploy/bin/activate && misc/download_wordpress.py > $@

checks: check-programs db.related.yaml

check-programs-pdf:
	@which  pdftk >/dev/null || ( \
		echo "You need to install pdftk."; \
		exit 1)

check-programs:
	(\
	. deploy/bin/activate; \
	\
	which  bibtex2html >/dev/null || ( \
		echo "You need to install bibtex2html."; \
		exit 2); \
	\
	which  mcdp-render >/dev/null  || ( \
		echo "The program mcdp-render is not found"; \
		echo "You are not in the virtual environment."; \
		exit 3); \
	\
	which  mcdp-split >/dev/null  || ( \
		echo "The program mcdp-split is not found"; \
		echo "You need to run 'python setup.py develop' from mcdp/."; \
		exit 4); \
	\
	which  convert >/dev/null  || ( \
		echo "You need to install ImageMagick"; \
		exit 2); \
	\
	which  gs >/dev/null  || ( \
		echo "You need to install Ghostscript (used by ImageMagick)."; \
		exit 2); \
	)

	@echo All programs installed.

check-duckietown-software:
	@if [ -d $(duckietown-software) ] ; \
	then \
	     echo '';\
	else \
		echo 'Please create a link "$(duckietown-software)" to the Software repository.'; \
		echo '(This is used to include the package documentation)'; \
		echo ''; \
		echo 'Assuming the usual layout, this is:'; \
		echo '      ln -s  ~/duckietown $(duckietown-software)'; \
		echo ''; \
		exit 1; \
	fi;

generated_figs=docs/generated_pdf_fig

inkscape2=/Applications/Inkscape.app/Contents/Resources/bin/inkscape

process-svg-clean:
	-rm -f $(generated_figs)/*pdf

process-svg:
	@which  inkscape >/dev/null || which $(inkscape2) || ( \
		echo "You need to install inkscape."; \
		exit 2)
	@which  pdfcrop >/dev/null || (echo "You need to install pdfcrop."; exit 1)
	@which  pdflatex >/dev/null || (echo "You need to install pdflatex."; exit 1)

	python -m mcdp_docs.process_svg docs/ $(generated_figs) $(tex-symbols)


books: \
	duckumentation \
	the_duckietown_project \
	opmanual_duckiebot \
	opmanual_duckietown \
	software_carpentry \
	software_devel \
	software_architecture \
	class_fall2017 \
	class_fall2017_projects \
	learning_materials \
	exercises \
	drafts \
	guide_for_instructors \
	deprecated \
	preliminaries \
	AI_driving_olympics

guide_for_instructors: checks
	. deploy/bin/activate && $(RUNBOOK) $@ docs/atoms_12_guide_for_instructors

deprecated: checks
	$(RUNBOOK) $@ docs/atoms_98_deprecated

AI_driving_olympics:
	$(RUNBOOK) $@ docs/atoms_16_driving_olympics

code_docs: check-duckietown-software checks
	$(RUNBOOK) $@ duckietown/catkin_ws/src/

class_fall2017: checks
	$(RUNBOOK) $@ docs/atoms_80_fall2017_info

drafts: checks
	$(RUNBOOK) $@ docs/atoms_99_drafts

preliminaries: checks
	$(RUNBOOK) $@ docs/atoms_29_preliminaries

learning_materials: checks
	$(RUNBOOK) $@ docs/atoms_30_learning_materials

exercises: checks
	$(RUNBOOK) $@ docs/atoms_40_exercises

duckumentation: checks
	$(RUNBOOK) $@ docs/atoms_15_duckumentation

the_duckietown_project: checks
	$(RUNBOOK) $@ docs/atoms_10_the_duckietown_project

opmanual_duckiebot: checks
	$(RUNBOOK) $@ docs/atoms_17_opmanual_duckiebot

opmanual_duckietown: checks
	$(RUNBOOK) $@ docs/atoms_18_setup_duckietown

software_carpentry: checks
	$(RUNBOOK) $@ docs/atoms_60_software_reference

software_devel: checks
	$(RUNBOOK) $@ docs/atoms_70_software_devel_guide

software_architecture: checks
	$(RUNBOOK) $@ docs/atoms_80_duckietown_software

class_fall2017_projects: checks
	$(RUNBOOK) $@ docs/atoms_85_fall2017_projects

clean:
	rm -rf out

duckuments-bot:
	python misc/slack_message.py

clean-tmp:
	find /mnt/tmp/mcdp_tmp_dir-duckietown -type d -ctime +10 -exec rm -rf {} \;

package-artifacts:
	bash package-art.sh out/package.tgz
