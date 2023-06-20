<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:atom="http://www.w3.org/2005/Atom">
  <xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd" doctype-public="XSLT-compat"/>
  <xsl:template match="/">
  <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
    <head>
      <title>
        <xsl:value-of select="/atom:feed/atom:title"/> - Atom feed
      </title>
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <style type="text/css">body { zoom: 200%; }</style>
    </head>
    <body>
      <p>
        This is an RSS feed. Visit
        <a href="https://aboutfeeds.com">About Feeds</a>
        to learn more and get started. It’s free.
      </p>
      <h1>Recent blog posts</h1>
      <xsl:for-each select="/atom:feed/atom:entry">
        <div>
          <p>
            <a>
              <xsl:attribute name="href">
                <xsl:value-of select="atom:link/@href"/>
              </xsl:attribute>
              <xsl:value-of select="atom:title"/>
            </a>
            Last updated:
            <xsl:value-of select="substring(atom:updated, 0, 11)" />
          </p>
          <p>
            <xsl:value-of select="atom:summary"/>
          </p>
        </div>
      </xsl:for-each>
    </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
