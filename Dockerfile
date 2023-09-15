FROM debian:bookworm-20230904 AS downloader

RUN apt update && apt install -y lbzip2 thunderbird

WORKDIR /installer
ADD https://download.mozilla.org/\?product\=thunderbird-latest\&os\=linux64\&lang\=en-US thunderbird.tar.gz
RUN tar xaf *.tar.gz
RUN mkdir /libs; \
	cp /usr/lib/x86_64-linux-gnu/libgthread-2.0.so.0 /libs; \
	ldd /usr/lib/x86_64-linux-gnu/libgthread-2.0.so.0 \
		/installer/thunderbird/thunderbird \
		/installer/thunderbird/thunderbird-bin \
		/installer/thunderbird/libmozgtk.so \
		/installer/thunderbird/libxul.so \
	| grep -v "not" | grep '=>' | awk '{ print $3; }' | xargs -I_ -n 1 cp _ /libs \
	;

FROM gcr.io/distroless/base-debian12:nonroot AS tb
COPY --from=downloader /installer/thunderbird /thunderbird
COPY --from=downloader /libs/* /usr/lib/
COPY --from=downloader /usr/share/fonts /usr/share/fonts
COPY --from=downloader /etc/fonts /etc/fonts
COPY --from=downloader /usr/share/icons /usr/share/icons
COPY --from=downloader /usr/share/mime /usr/share/mime
COPY --from=downloader /usr/share/glib-2.0 /usr/share/glib-2.0
ENTRYPOINT ["/thunderbird/thunderbird"]
