RUN chmod +x /entrypoint.sh
COPY sgn_local.conf /home/production/cxgn/sgn/sgn_local.conf
# this is a default sgn_local.conf with a temp password

# compile the simsearch and contigalign tools
#
RUN cd /home/production/cxgn/gtsimsrch/src; make; cd -;
RUN cd /home/production/cxgn/sgn/programs/; make; cd -;


# add npm
RUN curl -sL https://deb.nodesource.com/setup_24.x | bash -
RUN apt-get install nodejs -y
RUN cd /home/production/cxgn/sgn/js; npm install

#then a few steps to clean up permissions
RUN rm -rf /home/production/.npm
RUN chown -R production /home/production/cxgn/sgn/js/node_modules
RUN chown production /home/production/cxgn/sgn/js/package-lock.json


WORKDIR /home/production/cxgn/sgn

# add npm
RUN curl -sL https://deb.nodesource.com/setup_24.x | bash -
RUN apt install nodejs -y
RUN cd /home/production/cxgn/sgn/js; npm install

#then a few steps to clean up permissions
RUN rm -rf /home/production/.npm
RUN chown -R production /home/production/cxgn/sgn/js/node_modules
RUN chown production /home/production/cxgn/sgn/js/package-lock.json


ENV PERL5LIB=/home/production/cxgn/bio-chado-schema/lib:/home/production/cxgn/local-lib/:/home/production/cxgn/local-lib/lib/perl5:/home/production/cxgn/sgn/lib:/home/production/cxgn/cxgn-corelibs/lib:/home/production/cxgn/Phenome/lib:/home/production/cxgn/Cview/lib:/home/production/cxgn/ITAG/lib:/home/production/cxgn/biosource/lib:/home/production/cxgn/tomato_genome/lib:/home/production/cxgn/chado_tools/chado/lib:.

ENV HOME=/home/production
ENV PGPASSFILE=/home/production/.pgpass
RUN echo "R_LIBS_USER=/home/production/cxgn/R4.5_libs" >> /etc/R/Renviron
ENV R_LIBS_USER=/home/production/cxgn/R4.5_libs

COPY R_deps.R /home/production/R_deps.R

RUN Rscript --vanilla /home/production/R_deps.R

RUN ln -s /home/production/cxgn/starmachine/bin/starmachine_init.d /etc/init.d/sgn

ARG CREATED
ARG REVISION
ARG BUILD_VERSION

ENV VERSION=${BUILD_VERSION}
ENV BUILD_DATE=${CREATED}

LABEL maintainer="lam87@cornell.edu"
LABEL org.opencontainers.image.created=$CREATED
LABEL org.opencontainers.image.url="https://breedbase.org/"
LABEL org.opencontainers.image.source="https://github.com/solgenomics/breedbase_dockerfile"
LABEL org.opencontainers.image.version=$BUILD_VERSION
LABEL org.opencontainers.image.revision=$REVISION
LABEL org.opencontainers.image.vendor="Boyce Thompson Institute"
LABEL org.opencontainers.image.title="breedbase/breedbase"
LABEL org.opencontainers.image.description="Breedbase web server"
LABEL org.opencontainers.image.documentation="https://solgenomics.github.io/sgn/"



# start services when running container...
#
ENTRYPOINT ["/entrypoint.sh"]
