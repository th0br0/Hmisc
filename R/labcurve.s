## $Id$
## In future change grid.convert to convertUnit,
## grid.convertX to convertX, grid.convertY to convertY

labcurve <- function(curves, labels=names(curves), 
					 method=NULL, keys=NULL, keyloc=c('auto','none'),
                     type='l', step.type=c('left','right'),
                     xmethod=if(any(type=='s')) 'unique' else 'grid', 
					 offset=NULL,
                     xlim=NULL, tilt=FALSE, window=NULL,
                     npts=100, cex=NULL, 
					 adj='auto', angle.adj.auto=30, 
					 lty=pr$lty, lwd=pr$lwd, col.=pr$col,
					 transparent=TRUE, arrow.factor=1, 
					 point.inc=NULL, opts=NULL, key.opts=NULL, 
					 empty.method=c('area','maxdim'), 
					 numbins=25, 
					 pl=!missing(add), add=FALSE, 
					 ylim=NULL, xlab="", ylab="",
                     whichLabel=1:length(curves),
                     grid=FALSE, xrestrict=NULL, ...) {

  if(grid && !.R.) {
##    warning('specified grid=T under S-Plus, ignored')
    grid <- FALSE
  }

  if(.R. && pl && !add) {plot.new(); par(new=TRUE)}  # enables strwidth etc.
  ## added !add 11dec02

  if(.R.) {
    oxpd <- par('xpd')
    par(xpd=NA)
    on.exit(par(xpd=oxpd))
  }
  
  gfun <- ordGridFun(.R. && grid)    ## see Misc.s
  gun  <- gfun$unit

  diffu <- function(v) diff(oldUnclass(v))  # mainly for POSIXt 17jun02
  ## also look at difftime
  
  mcurves <- missing(curves)

  pr <- par(c('cex','col','lwd','lty'))

  if(!mcurves) {
	nc <- length(curves)
	type <- rep(type, length=nc)
	lty  <- rep(lty,  length=nc)
	lwd  <- rep(lwd,  length=nc)
	col. <- rep(col., length=nc)
	for(i in 1:nc) {
	  z <- curves[[i]]
	  if(pl && !add) {
		if(i==1) {
		  xlm <- range(z[[1]],na.rm=TRUE)
		  ylm <- range(z[[2]],na.rm=TRUE)
		} else {
		  xlm <- range(xlm,z[[1]],na.rm=TRUE)
		  ylm <- range(ylm,z[[2]],na.rm=TRUE)
		}
	  }
	  if(length(a <- z$type)) type[i] <- a
	  if(length(a <- z$lty))  lty[i]  <- a
	  if(length(a <- z$lwd))  lwd[i]  <- a
	  if(length(a <- z$col))  col.[i] <- a
	}
  }

  ## Optionally bring arguments from opts as if they were listed outside opts
  ## This is used when opts is passed through to a function calling labcurve
  if(length(opts) && is.list(opts)) {
	names.opts <- names(opts)
	full.names <- c('labels','method','keys','keyloc','type','step.type',
					'xmethod','offset','xlim','tilt','window','npts','cex',
					'adj','angle.adj.auto','lty','lwd','col.','n.auto.keyloc',
					'transparent','arrow.factor','point.inc','key.opts',
					'empty.method','numbins','ylim','xlab','ylab')
	i <- charmatch(names.opts, full.names, -1)
	if(any(i < 1)) stop(paste('Illegal elements in opts:',
							  paste(names.opts[i < 1], collapse=' ')))
	for(j in 1:length(opts)) assign(full.names[i[j]],opts[[j]],immediate=TRUE)
  }

  if(mcurves) nc <- length(labels) else
    if(!is.logical(labels) && nc != length(labels))
      stop('length of labels is not equal to # curves')  #28Nov99

  type <- rep(type, length=nc)
  lty  <- rep(lty,  length=nc)
  lwd  <- rep(lwd,  length=nc)
  col. <- rep(col., length=nc)

  if(pl) {
	if(mcurves) stop('curves must be given if pl=T')
	if(!add) {
	  if(!length(xlim)) xlim <- xlm
	  if(!length(ylim)) ylim <- ylm
	  namcur <- names(curves[[1]])   #13Jul97
	  if(xlab=='' && length(namcur)) xlab <- namcur[1]
	  if(ylab=='' && length(namcur)) ylab <- namcur[2]
      if(grid) {
        stop("grid=TRUE when pl=TRUE is not yet implemented")
      } else
      plot(0, 0, xlim=xlim, ylim=ylim, xlab=xlab, ylab=ylab,
           type='n', xaxt='n')  ## xaxt 15jun02
      if(inherits(xlim,'POSIXt') || inherits(xlim,'POSIXct'))
        axis.POSIXct(1) else axis(1)   ## 15jun02 18sep02
            
	  pr <- par(c('cex','col','lwd','lty'))
	}
	for(i in 1:nc) {
	  z <- curves[[i]]
	  gfun$lines(z[[1]], z[[2]],
                 type=type[i], lty=lty[i], lwd=lwd[i], col=col.[i])
	}
  }

  if(length(method) && method=='none') return(invisible()) # 29sep02

  pr <- parGrid(grid)  ## 20Mar02
  usr <- pr$usr; uin <- pr$uin
  
  is.keys    <- length(keys) > 0
  lines.keys <- length(keys)==1 && is.character(keys) && keys=='lines'

  if(!length(method)) {
	if(is.keys) method <- if(is.numeric(keys) || lines.keys)
	  'on top' else 'offset' else
	method <- 'offset'
  }

  ## Expand abbreviations for method - couldn't use match.arg
  possible.methods <- c('offset','on top','arrow','mouse','locator')
  i <- charmatch(method, possible.methods, -1)
  if(i < 1) stop(paste('method must be one of ',
					   paste(possible.methods,collapse=' ')))
  method <- possible.methods[i]
  
  if(!length(cex)) cex <- pr$cex

  if(mcurves && method %nin% c('mouse','locator')) 
	  stop('must specify curves unless method="mouse" or "locator"')

  if(!lines.keys && is.keys && length(keys) != nc) 
	stop('number of keys must = number of curves')

  if(method %in% c('mouse','locator')) {
	if(adj=='auto') adj <- .5
	xt <- yt <- numeric(nc)
	for(i in 1:nc) {
      if(i %in% whichLabel) {  ## 17sep02
        cat('\nPosition pointer to desired center of curve label and click for',
            labels[i],'\n')
        lab.pos <- locator(1)
        xt[i] <- lab.pos$x
        yt[i] <- lab.pos$y
        gfun$text(lab.pos, labels[i], cex=cex, adj=adj, col=col.[i],
                  ...)
      }
	}
	return(invisible(list(x=xt, y=yt, offset=0,
						  adj=adj, cex=cex, angle=0, col=col., lwd=lwd,
						  key.opts=key.opts, ...)))
  }

  if(is.character(keyloc)) keyloc <- match.arg(keyloc)

  empty.method <- match.arg(empty.method)

  if(!length(offset)) offset <-
    if(grid)unit(.75,"strheight","m") else strheight('m','user', cex)*.75

  if(!length(xlim)) xlim <- usr[1:2]
  if(!length(ylim)) ylim <- usr[3:4]

  ##  if(!length(point.inc)) point.inc <- diff(xlim)/5
  ## moved to be used only when needed 15jun02

  if(nc==1) {
	ci <- curves[[1]]
	xx <- ci[[1]]; yy <- ci[[2]]
	s <- is.finite(xx+yy)
	xx <- xx[s];  yy <- yy[s]
	imid <- trunc((length(xx)+1)/2)
	adj <- if(is.character(adj))0.5 else adj
	if(any(whichLabel==1))
      gfun$text(xt <- gun(xx[imid]),
                yt <- gun(yy[imid])+offset,
                labels, 
                cex=cex, adj=adj, col=col., ...)
	return(invisible(list(x=xt, y=yt, offset=offset,
						  adj=adj, cex=cex, col=col., lwd=lwd, angle=0, 
						  key.opts=key.opts, ...)))
  }

  if(xmethod %nin% c('grid','unique')) 
	stop('xmethod must be "grid" or "unique"')
  step.type <- match.arg(step.type)


  if(is.character(adj)) {
	adj.does.vary     <- TRUE
	adj.needs.to.vary <- TRUE
	adj <- rep(.5, nc)
  } else {
	adj.does.vary     <- length(adj) > 1
	adj.needs.to.vary <- FALSE
	adj <- rep(adj, length=nc)
  }

  if(xmethod=='grid') xs <- seq(xlim[1],xlim[2],length=npts) else {
	xs <- unlist(sapply(curves, function(z)z[[1]]))
	xs <- sort(unique(xs[!is.na(xs)]))
	xs <- xs[xs>=xlim[1] & xs<=xlim[2]]
  }

  ys <- matrix(NA, nrow=length(xs), ncol=nc)
  rng <- matrix(NA, nrow=2, ncol=nc)

  for(i in 1:nc) {
	ci <- curves[[i]]
	xx <- ci[[1]]; yy <- ci[[2]]
	s <- is.finite(xx+yy)
	xx <- xx[s]
	y <- approx(xx, yy[s], xout=xs, f=if(step.type=='left')0 else 1,
				method=if(type[i]=='l')"linear" else "constant")$y
	y <- pmax(pmin(y,usr[4]),usr[3])
	## Where one curve is not defined, consider this gap to have an ordinate
	## that is far from the other curves so labels where be placed where
	## the other curves haven't started or after they've ended
	y[is.na(y)] <- 1e10
	ys[,i] <- y
    rxx <- range(xx) ## 12feb03 and next 5 lines
    if(length(xrestrict)) {
      rxx[1] <- max(rxx[1],xrestrict[1])
      rxx[2] <- min(rxx[2],xrestrict[2])
    }
	rng[,i] <- rxx
	## Save real range of each x-vector so candidates for labeling
	## will be where the curve really exists
  }

  if(method=='on top' && is.keys && is.numeric(keys)) {
	## Draw periodic symbols
	sym <- function(curve, pch, inc, offset, type, step.type, col.,
                    grid, gfun) {
	  x <- curve[[1]]; y <- curve[[2]]
	  s <- is.finite(x+y)
	  x <- x[s]; y <- y[s]
	  if(length(x)<2)
        stop("when specifying numeric keys (pch) you must have >=2 data points")
	  lim <- range(x)
      ## Next line was gun(seq())+offset,'x'  7apr03
##	  xx <- if(grid)convertNative(gun(seq(lim[1],lim[2],by=inc) +  24feb04
##                                  offset),'x') else
      xx <- if(grid)
        grid.convertX(gun(seq(lim[1],lim[2],by=inc) + offset),
                          'native', valueOnly=TRUE) else
	   seq(lim[1], lim[2], by=inc) + offset
	  if(length(xx)>1) xx <- xx[-1]
	  xx <- xx[xx<=lim[2]]
	  if(length(xx)==0) 
		warning('curve was too short to mark with a symbol.\nMay want to change point.inc or xmethod for labcurve')
	  else {
		yy <- approx(x, y, xout=xx,
                     method=if(type=='l')'linear' else 'constant', 
					 f=if(step.type=='left')0 else 1)$y
	  gfun$points(xx, yy, pch=pch, col=col.)
	  }
	}
    if(!length(point.inc)) point.inc <- diffu(xlim)/5
	for(i in 1:nc) sym(curves[[i]], keys[i], point.inc, (i-1)*point.inc/nc,
					   type[i], step.type, col.=col.[i],
                       grid, gfun)
	xt <- yt <- NULL
  } else {
	xt <- yt <- direction <- numeric(nc)
	angle <- rep(0,nc)

	g <- function(x) {  # finds min(abs(x)) but keeps original sign
	  ax <- abs(x)
      if(all(is.na(ax))) return(NA)   ## 29Jan02
	  w <- min(ax, na.rm=TRUE)
	  (x[ax==w])[1]   #use first occurrence
	}
	for(i in 1:nc) {
	  yi <- ys[,i]
	  yi[xs<rng[1,i] | xs>rng[2,i]] <- NA
	  diffmat <- ys[,-i,drop=FALSE] - yi
	  mindiff <- apply(diffmat, 1, g)
	  z <- abs(mindiff)==max(abs(mindiff),na.rm=TRUE)
	  maxid   <- min(c(1:length(mindiff))[z], na.rm=TRUE)
	  xt[i] <- xs[maxid]
	  yt[i] <- ys[maxid,i]
      if(!is.na(mindiff[maxid])) 
        direction[i] <- 1-2*(mindiff[maxid]>0)  ## if 16may03 + next if
	  yto <- yt[i] +
#        direction[i]*(if(grid)convertNative(offset,'y') else offset) 24feb04
        direction[i]*
          (if(grid)grid.convertY(offset,'native',valueOnly=TRUE) else offset)
        if(!is.na(yto)) 
      if(yto >= usr[4] || yto <= usr[3]) direction[i] <- -direction[i]

	  ## Find slope of curve i at xt[i]
	  if(tilt || adj.needs.to.vary) {
		angle[i] <- if(type[i]=='s') 0 else {
		  ci <- curves[[i]]
		  xx <- ci[[1]]; yy <- ci[[2]]
		  s <- is.finite(xx+yy)
		  w <- if(length(window)) window else {
			nch <- if(lines.keys) nchar(labels[i]) else 
			if(is.keys) 1*is.numeric(keys) + 
			  nchar(keys[i])*is.character(keys) else nchar(labels[i])
			w <- if(grid)
#              nch*convertNative(unit(.75,"strwidth","m"),'x') else 24feb04
              nch*grid.convertX(unit(.75,"strwidth","m"),
                                'native',valueOnly=TRUE) else
              nch*strwidth('m','user',cex)
		  }
		  yy <- approx(xx[s], yy[s], xout=c(xt[i]-w/2,xt[i]+w/2),
					   rule=2)$y
		  slope <- diff(yy)/w
		  180*atan(slope*uin[2]/uin[1])/pi
		}
	  }
	  if(adj.needs.to.vary) {
		adj[i] <- if(type[i]=='s') 1*(direction[i]<0) else {
          ## is.na(angle[i]) 16may03
		  if(is.na(angle[i]) || abs(angle[i])<=angle.adj.auto).5 else
		  if((direction[i]<0 && slope>0) || 
			 (direction[i]>0 && slope<0)) 0 else 1
		}
	  }
	}

	if(!tilt) angle[] <- 0
	if(!lines.keys && method=='offset' && (!is.logical(labels) || labels)) {
	  if(is.keys) {
		if(is.numeric(keys)) for(i in 1:nc)
		  gfun$points(xt[i], (gun(yt) + direction*offset)[i], 
                      pch=keys[i], col=col.[i])
		  else if(i %in% whichLabel)    ## 17sep02
            gfun$text(xt, gun(yt) + direction*offset,
                      keys, cex=cex,  
                      adj=adj[1], col=col., ...)
	  }
		else {
		  if(tilt || adj.does.vary) for(i in whichLabel)   ## 17sep02
			gfun$text(xt[i], gun(yt[i])+direction[i]*offset, 
                      labels[i], cex=cex, srt=angle[i], 
                      adj=adj[i], col=col.[i],...) else
		  gfun$text(xt, gun(yt)+direction*offset, labels, 
                    cex=cex, adj=adj[1], col=col., ...)
		}
	}
	retlist <- list(x=xt, y=yt, offset=direction*offset,
					adj=adj, cex=cex, col=col., lwd=lwd, angle=if(tilt) angle, 
					key.opts=key.opts, ...)
  }

  if(method %in% c('on top','arrow') && (!is.logical(labels) || labels)) {

	retlist <- list(x=xt, y=yt, offset=0, 
					adj=.5, cex=cex, col=col., lwd=lwd, angle=0, 
					key.opts=key.opts, ...)

	if(method == 'on top' && !lines.keys) {
	  if(is.keys) {
		if(is.character(keys))
		  gfun$text(xt, yt, keys, cex=cex, col=col., adj=.5, ...)
		## numeric keys (periodic plotting symbols) already handled above
	  } else gfun$text(xt, yt, labels, cex=cex, col=col., adj=.5, ...)
	} else if(method=='arrow') {
	  ydelta <- if(grid)unit(1/17,'npc') else diffu(ylim)/17
	  xdelta <- if(grid)unit(1/26,'npc') else diffu(xlim)/26
	  lab.pos <- list(x=gun(xt) + xdelta*arrow.factor,
					  y=gun(yt) + ydelta*arrow.factor)

	  gfun$arrows(gun(xt)+xdelta*.6*arrow.factor,
                  gun(yt)+ydelta*.6*arrow.factor,
                  xt,yt,open=TRUE,size=.06,col=col.)
	  gfun$text(lab.pos, labels, cex=cex, col=col., ...)
	}
  }


  if(is.keys && (!is.character(keyloc) || keyloc!='none')) {
	## Make legend

    s <- whichLabel   ## 17sep02
	if(is.character(keyloc) && keyloc=='auto') {
	  ## Find emptiest spot for drawing legend by finding
	  ## center of largest empty rectangle large enough to hold 
	  ## this rectangle
	  Xs <- rep(xs, nc)
	  Ys <- as.vector(ys)
      putKeyEmpty(Xs, Ys,
                  labels=if(lines.keys || is.numeric(keys))labels[s] else
                   paste(keys,'    ',labels, sep='')[s],  # 27may02
                  pch=if(is.numeric(keys)) keys[s],
                  lty=lty[s], lwd=lwd[s], cex=cex, col=col.[s],
                  transparent=transparent, plot=TRUE,
                  key.opts=key.opts, xlim=xlim, ylim=ylim, grid=grid)
      ## added xlim 16Mar02
	} else putKey(keyloc,
                  labels=if(lines.keys || is.numeric(keys))labels[s] else
                   paste(keys,'    ',labels, sep='')[s],  # 27may02
                  pch=if(is.numeric(keys)) keys[s],
                  lty=lty[s], lwd=lwd[s], cex=cex, col=col.[s],
                  transparent=transparent, plot=TRUE,
                  key.opts=key.opts, grid=grid) # remove ylim 1Mar01
  }

  invisible(retlist)
}

# Version of legend for R that implements plot=FALSE, adds grid=TRUE
# Also defaults lty, lwd, pch to NULL and checks for length>0 rather
# than missing(), so it's easier to deal with non-applicable parameters
if(.R.) {
  rlegend <- function (x, y, legend, fill, col = "black", lty=NULL, lwd=NULL,
                       pch=NULL, angle = NULL,  
                       density = NULL, bty = "o", bg = par("bg"),
                       pt.bg = NA, cex = 1, 
                       xjust = 0, yjust = 1, x.intersp = 1, y.intersp= 1,
                       adj = 0, text.width = NULL,
                       merge = do.lines && has.pch, trace = FALSE, 
                       ncol = 1, horiz = FALSE, plot=TRUE, grid=FALSE,
                       ...) {

    gfun <- ordGridFun(grid)   ## see Misc.s

    if (is.list(x)) {
        if (!missing(y)) {
            if (!missing(legend)) 
                stop("`y' and `legend' when `x' is list (need no `y')")
            legend <- y
        }
        y <- x$y
        x <- x$x
    }
    else if (missing(y)) 
        stop("missing y")
    if (!is.numeric(x) || !is.numeric(y)) 
        stop("non-numeric coordinates")
    if ((nx <- length(x)) <= 0 || nx != length(y) || nx > 2) 
        stop("invalid coordinate lengths")
    xlog <- par("xlog")
    ylog <- par("ylog")
    rect2 <- function(left, top, dx, dy, ...) {
        r <- left + dx
        if (xlog) {
            left <- 10^left
            r <- 10^r
        }
        b <- top - dy
        if (ylog) {
            top <- 10^top
            b <- 10^b
        }
        gfun$rect(left, top, r, b, angle = angle, density = density, 
                  ...)
    }
    segments2 <- function(x1, y1, dx, dy, ...) {
        x2 <- x1 + dx
        if (xlog) {
            x1 <- 10^x1
            x2 <- 10^x2
        }
        y2 <- y1 + dy
        if (ylog) {
            y1 <- 10^y1
            y2 <- 10^y2
        }
        gfun$segments(x1, y1, x2, y2, ...)
    }
    points2 <- function(x, y, ...) {
        if (xlog) 
            x <- 10^x
        if (ylog) 
            y <- 10^y
        gfun$points(x, y, ...)
    }
    text2 <- function(x, y, ...) {
        if (xlog) 
            x <- 10^x
        if (ylog) 
            y <- 10^y
        gfun$text(x, y, ...)
    }
    if (trace) 
        catn <- function(...) do.call("cat", c(lapply(list(...), 
            formatC), list("\n")))
    pr  <- parGrid(grid)  ## 20Mar02 FEH
    cin <- pr$cin         ## FEH
    Cex <- cex * pr$cex   ## FEH
    if (!length(text.width)) ## FEH
        text.width <- max(strwidth(legend, u = "user", cex = cex))
    else if (!is.numeric(text.width) || text.width < 0) 
        stop("text.width must be numeric, >= 0")
    xc <- Cex * xInch(cin[1], warn.log = FALSE, grid=grid)  ## FEH in Misc.s
    yc <- Cex * yInch(cin[2], warn.log = FALSE, grid=grid)  ## FEH
    xchar <- xc
    yextra <- yc * (y.intersp - 1)
    ymax <- max(yc, strheight(legend, u = "user", cex = cex))
    ychar <- yextra + ymax
    if (trace) 
        catn("  xchar=", xchar, "; (yextra,ychar)=", c(yextra, 
            ychar))
    if (!missing(fill)) {
        xbox <- xc * 0.8
        ybox <- yc * 0.5
        dx.fill <- xbox
    }
    do.lines <- (length(lty) && any(lty > 0)) || length(lwd)
    n.leg <- length(legend)
    n.legpercol <- if (horiz) {
        if (ncol != 1) 
            warning(paste("horizontal specification overrides: Number of columns :=", 
                n.leg))
        ncol <- n.leg
        1
    }
    else ceiling(n.leg/ncol)
    if (has.pch <- length(pch)) {
        if (is.character(pch) && nchar(pch[1]) > 1) {
            if (length(pch) > 1) 
                warning("Not using pch[2..] since pch[1] has multiple chars")
            np <- nchar(pch[1])
            pch <- substr(rep(pch[1], np), 1:np, 1:np)
        }
        if (!merge) 
            dx.pch <- x.intersp/2 * xchar
    }
    x.off <- if (merge) 
        -0.7
    else 0
    if (xlog) 
        x <- log10(x)
    if (ylog) 
        y <- log10(y)
    if (nx == 2) {
        x <- sort(x)
        y <- sort(y)
        left <- x[1]
        top <- y[2]
        w <- diff(x)
        h <- diff(y)
        w0 <- w/ncol
        x <- mean(x)
        y <- mean(y)
        if (missing(xjust)) 
            xjust <- 0.5
        if (missing(yjust)) 
            yjust <- 0.5
    }
    else {
        h <- n.legpercol * ychar + yc
        w0 <- text.width + (x.intersp + 1) * xchar
        if (!missing(fill)) 
            w0 <- w0 + dx.fill
        if (has.pch && !merge) 
            w0 <- w0 + dx.pch
        if (do.lines) 
            w0 <- w0 + (2 + x.off) * xchar
        w <- ncol * w0 + 0.5 * xchar
        left <- x - xjust * w
        top <- y + (1 - yjust) * h
    }
    if (bty != "n") {
        if (trace) 
            catn("  rect2(", left, ",", top, ", w=", w, ", h=", 
                h, "...)", sep = "")
        if(plot) rect2(left, top, dx = w, dy = h, col = bg)  ## FEH
    }
    xt <- left + xchar + (w0 * rep(0:(ncol - 1), rep(n.legpercol, 
        ncol)))[1:n.leg]
    yt <- top - (rep(1:n.legpercol, ncol)[1:n.leg] - 1) * ychar - 
        0.5 * yextra - ymax
    if (!missing(fill)) {
        fill <- rep(fill, length.out = n.leg)
        if(plot) rect2(left = xt, top = yt + ybox/2, dx = xbox, dy = ybox, 
            col = fill)   ## FEH
        xt <- xt + dx.fill
    }
    if (has.pch || do.lines) 
        col <- rep(col, length.out = n.leg)
    if (do.lines) {
        seg.len <- 2
        ok.l <- if (!length(lty)) {
            lty <- 1
            TRUE
        }
        else lty > 0
        if (!length(lwd)) 
            lwd <- pr$lwd   ## FEH
        lty <- rep(lty, length.out = n.leg)
        lwd <- rep(lwd, length.out = n.leg)
        if (trace) 
            catn("  segments2(", xt[ok.l] + x.off * xchar, ",", 
                yt[ok.l], ", dx=", seg.len * xchar, ", dy=0, ...)", 
                sep = "")
        if(plot)segments2(xt[ok.l] + x.off * xchar, yt[ok.l], dx = seg.len * 
            xchar, dy = 0, lty = lty[ok.l], lwd = lwd[ok.l], 
            col = col[ok.l])   ## FEH
        xt <- xt + (seg.len + x.off) * xchar
    }
    if (has.pch) {
        pch <- rep(pch, length.out = n.leg)
        pt.bg <- rep(pt.bg, length.out = n.leg)
        ok <- is.character(pch) | pch >= 0
        x1 <- (if (merge) 
            xt - (seg.len/2) * xchar
        else xt)[ok]
        y1 <- yt[ok]
        if (trace) 
            catn("  points2(", x1, ",", y1, ", pch=", pch[ok], 
                "...)")
        if(plot)points2(x1, y1, pch = pch[ok], col = col[ok], cex = cex, 
            bg = pt.bg[ok])  ## FEH
        if (!merge) 
            xt <- xt + dx.pch
    }
    xt <- xt + x.intersp * xchar
    if(plot)text2(xt, yt, labels = legend, adj = adj, cex = cex) ## FEH
    invisible(list(rect = list(w = w, h = h, left = left, top = top), 
                   text = list(x = xt, y = yt)))
  }
  NULL
}

putKey <- function(z, labels, type=NULL,
                   pch=NULL, lty=NULL, lwd=NULL,
                   cex=par('cex'), col=rep(par('col'),nc),
                   transparent=TRUE, plot=TRUE, key.opts=NULL, grid=FALSE) {

  if(grid) {
    require('grid')
    require('lattice')  # use draw.key in lattice    29Jan02
  }
  
  if(!.R. && !existsFunction('key')) 
    stop('must do library(trellis) to access key() function')

  nc <- length(labels)
  if(!length(pch)) pch <- rep(NA, nc)
  if(!length(lty)) lty <- rep(NA, nc)
  if(!length(lwd)) lwd <- rep(NA, nc)
  
  pp <- !is.na(pch)
  lp <- !is.na(lty) | !is.na(lwd)
  lwd <- ifelse(is.na(lwd), par('lwd'), lwd)
  
  if(!length(type)) type <- ifelse(!(pp | lp), 'n',
                                   ifelse(pp & lp, 'b',
                                          ifelse(pp, 'p', 'l')))
  
  pch <- ifelse(is.na(pch) & type!='p' & type!='b',
                if(.R.)NA else 0, pch)  ## NA was 0 12dec02
  lty <- ifelse(is.na(lty) & type=='p',
                if(.R.)NA else 1, lty)  ## NA was 1 12dec02
  lwd <- ifelse(is.na(lwd) & type=='p', 1, lwd)
  cex <- ifelse(is.na(cex) & type!='p' & type!='b', 1, cex)

  if(!.R. && any(is.na(pch))) stop("pch can not be NA for type='p' or 'b'") #12dec02
  if(!.R. && any(is.na(lty))) stop("lty can not be NA for type='l' or 'b'") #12dec02
  if(any(is.na(lwd))) stop("lwd can not be NA for type='l' or 'b'")
  if(any(is.na(cex))) stop("cex can not be NA for type='p' or 'b'")
  
  m <- list()
  m[[1]] <- as.name(if(grid)'draw.key' else if(.R.)'rlegend' else 'key')
  if(!grid) {m$x <- z[[1]]; m$y <- z[[2]]}

  if(.R.) {
    if(grid) {
      w <- list(text=list(labels, col=col))
      ##    m$xjust <- m$yjust <- 0.5
      if(!(all(is.na(lty)) & all(is.na(lwd)))) {
        lns <- list()
        if(!all(is.na(lty))) lns$lty <- lty
        if(!all(is.na(lwd))) lns$lwd <- lwd
        lns$col <- col
        w$lines <- lns
      }
      if(!all(is.na(pch))) w$points <- list(pch=pch, col=col)
      ## was if(!all(is.na(pch)) && !all(pch==0)) w$points <- list(pch=pch, col=col) 12dec02
      ##    if(length(key.opts)) m[names(key.opts)] <- key.opts
      m$key <- w
      m$draw <- plot
      if(plot) m$vp <-
        viewport(x=unit(z[[1]],'native'),y=unit(z[[2]],'native'))
      z <- eval(as.call(m))
      size <- if(plot) c(NA,NA) else {
        v <- as.numeric(version$major) + as.numeric(version$minor)/100
        if(v > 1.0709) {
          width <- getFromNamespace('width','grid')
          height <- getFromNamespace('height','grid')
        }
#        c(convertNative(width(z), 'x', 'dimension')[1], 24feb04
#          convertNative(height(z),'y', 'dimension')[1])
        c(grid.convert(width(z), 'native', 'x', 'location', 'x',
                        'dimension', valueOnly=TRUE)[1],
          grid.convert(height(z), 'native', 'y', 'location', 'y',
                        'dimension', valueOnly=TRUE)[1])
      }
      return(invisible(size))
    } else {
      m$legend <- labels
      m$xjust <- m$yjust <- .5
      m$plot <- plot
      m$col <- col
      m$cex <- cex
      if(!all(is.na(lty))) m$lty <- lty
      if(!all(is.na(lwd))) m$lwd <- lwd
      if(!all(is.na(pch))) m$pch <- pch
      ## was if(!all(is.na(pch)) && !all(pch==0)) m$pch <- pch 12dec02
      if(length(key.opts)) m[names(key.opts)] <- key.opts
      w <- eval(as.call(m))$rect
      return(invisible(c(w$w[1], w$h[1])))
    }
  }
  
  m$transparent <- transparent
  m$corner <- c(.5,.5)
  m$plot   <- plot
  m$type   <- type

  if(!plot) labels <- substring(labels, 1, 10)
  ## key gets length wrong for long labels
  m$text <- list(labels, col=col)
  if(all(type=='p')) m$points <- list(pch=pch, cex=cex, col=col)
  else m$lines <- if(any(type!='l'))
    list(lty=lty, col=col, lwd=lwd, pch=pch, cex=cex) else
  list(lty=lty, col=col, lwd=lwd)
                                                 
  if(length(key.opts)) m[names(key.opts)] <- key.opts
  invisible(eval(as.call(m)))  ## execute key(....)
}

putKeyEmpty <- function(x, y, labels, type=NULL,
                        pch=NULL, lty=NULL, lwd=NULL,
                        cex=par('cex'), col=rep(par('col'),nc),
                        transparent=TRUE, plot=TRUE, key.opts=NULL,
                        empty.method=c('area','maxdim'), 
                        numbins=25, 
                        xlim=pr$usr[1:2], ylim=pr$usr[3:4],
                        grid=FALSE) { 
  nc <- length(labels)
  empty.method <- match.arg(empty.method)

  pr <- parGrid(grid)
  uin <- pr$uin

  if(.R.) uin <- 1  ## already in x,y units
  z <- putKey(list(0, 0), labels, type, pch, lty, lwd, cex, col,
              transparent=transparent, plot=FALSE,
              key.opts=key.opts, grid=grid)/uin
  ## /uin converts to x,y units

  ## Find center of largest empty rectangle large enough to hold 
  ## this rectangle
  s  <- is.finite(x + y)
  if(length(xlim)) s <- s & (x >= xlim[1] & x <= xlim[2])
  if(length(ylim)) s <- s & (y >= ylim[1] & y <= ylim[2])
  x <- x[s]
  y <- y[s]
  keyloc <- largest.empty(x, y, xlim=xlim, ylim=ylim,
                          width=z[1], height=z[2],
                          method=empty.method, numbins=numbins, grid=grid)
  if(is.na(keyloc$x)) {
    cat('No empty area large enough for automatic key positioning.  Specify keyloc or cex.\n')
    cat('Width and height of key as computed by key(), in data units:',
        format(z),'\n')
    return(keyloc)
  } else if(plot) putKey(keyloc, labels, type,
                         pch, lty, lwd, cex, col, transparent, plot=TRUE,
                         key.opts=key.opts, grid=grid)
  invisible(keyloc)
}

largest.empty <- function(x, y, 
						  width, height, 
						  numbins=25,
						  method=c('area','maxdim'),
						  xlim=pr$usr[1:2], ylim=pr$usr[3:4],
						  pl=FALSE, grid=FALSE) {
  method <- match.arg(method)
  pr <- parGrid(grid)
  
  itype  <- 1*(method=='area')+2*(method=='maxdim')
  storage.mode(x) <- storage.mode(y) <- storage.mode(xlim) <-
	storage.mode(ylim) <- storage.mode(width) <-
      storage.mode(height) <- 'double'
  storage.mode(numbins) <- storage.mode(itype) <- 'integer'

  a <- if(.R.)
    .Fortran('largrec', x, y, length(x), 
             xlim, ylim, 
             width, height, numbins, itype,
             rx=double(2), ry=double(2), PACKAGE="Hmisc") else
    .Fortran('largrec', x, y, length(x), 
				xlim, ylim, 
				width, height, numbins, itype,
				rx=double(2), ry=double(2))
  x <- a$rx
  if(any(x > 1e29)) {
	warning('no empty rectangle was large enough')
	return(list(x=NA, y=NA))
  }
  y <- a$ry
  if(pl) ordGridFun(grid)$polygon(x[c(1,2,2,1)],y[c(1,1,2,2)], col=1+itype)
  list(x=mean(x), y=mean(y))
}


drawPlot <- function(..., xlim=c(0,1), ylim=c(0,1), xlab='', ylab='',
                     ticks=c('none','x','y','xy'),
                     key=FALSE, opts=NULL) {

  Points <- function(label=' ', type=c('p','r'), n, pch=pch.to.use[1],
                     cex=par('cex'), rug=c('none','x','y','xy'),
                     ymean=NULL) {
    type <- match.arg(type)
    rug <- match.arg(rug)
    cat('\nClick mouse for each point',
        if(label!='')paste(' for group ',label),'.',
        if(missing(n))' Right click when finished.', '\n',sep='')
    pts <- if(missing(n)) locator(type='p',pch=pch,cex=cex) else
      locator(n, type='p', pch=pch, cex=cex)
    if(length(ymean)) pts$y <- pts$y - mean(pts$y) + ymean  ## 26Jan01
    if(type=='p') 
      storeTemp(pch.to.use[pch.to.use != pch],'pch.to.use')
    else {
      scat1d(pts$x, side=1)
      pch <- NA
    }
    switch(rug,
           x = scat1d(pts$x, side=1),
           y = scat1d(pts$y, side=2),
           xy = {scat1d(pts$x, side=1); scat1d(pts$y, side=2)},
           none = )
           
    structure(list(points=pts, label=label, type=type,
                   pch=pch, cex=cex, rug=rug), class='Points')
  }

  Curve <- function(label=' ',
                    type=c('bezier','polygon','linear','pol','step','gauss'),
                    n=NULL, lty=1, lwd=par('lwd'), degree=2,
                    evaluation=100, ask=FALSE) {
    isfun <- is.function(type)
    if(!isfun) type <- match.arg(type)
    if(!isfun && !length(n) && type=='linear') n <- 2
    if(!isfun && type=='gauss') n <- 3
    xlim <- par('usr')[1:2]
    redraw <- TRUE
    
    if(isfun) {
      x <- seq(xlim[1], xlim[2], length=evaluation)
      pts <- list(x=as.single(x), y=as.single(type(x)))
      lines(pts, lty=lty, lwd=lwd)
    } else repeat {
      cat('\nClick mouse for each point',
          if(label!='')paste(' for group ',label),'.',
          if(!length(n))' Right click when finished.', '\n', sep='')
      pts <- if(!length(n)) locator(type='l', lty=lty, lwd=lwd) else
      locator(n, type='l', lty=lty, lwd=lwd)
      n <- length(pts$x)
      if(n < 2) stop('must click at least 2 points')
      if(n==2) type <- 'linear'

      if(type=='pol') {
        x <- matrix(NA, nrow=n, ncol=degree)
        for(i in 1:degree) x[,i] <- pts$x^i
        f <- lm.fit.qr.bare(x, pts$y)
        x <- matrix(NA, nrow=evaluation, ncol=degree)
        x[,1] <- seq(min(pts$x),max(pts$x), length=evaluation)
        if(degree > 1) for(i in 1:degree) x[,i] <- x[,1]^i
        cof <- f$coefficients
        y <- cof[1] + x %*% cof[-1]
        pts <- list(x=as.single(x[,1]), y=as.single(y))
        if(redraw) lines(pts, lty=lty, lwd=lwd)
      }

      if(type=='bezier') {
        pts <- bezier(pts, xlim=range(pts$x), evaluation=evaluation)
        if(redraw) lines(pts, lty=lty, lwd=lwd)
      }
      if(type=='gauss') {
        mu <- pts$x[2]
        delta <- diff(pts$x[-2])/2
        htavg <- sum(pts$y[-2])/2
        htmax <- pts$y[2]
        x <- seq(xlim[1], xlim[2], length=evaluation)
        b2 <- delta^2 / log(htmax/htavg)
        y <- htmax * exp(-(x-mu)^2/b2)
        i <- y > 1e-4
        pts <- list(x=as.single(x[i]), y=as.single(y[i]))
        lines(pts, lty=lty, lwd=lwd)
      }
      if(type=='step' && redraw)
        lines(pts, type='s', lty=lty, lwd=lwd)

      if(!ask) break
      if(readline('\nType y to accept, n to re-draw:')=='y') break
    }
    
    structure(list(points=pts, label=label, type=type, lty=lty,
                   lwd=lwd),  class='Curve')
  }

  Abline <- function(...) {
    abline(...)
    structure(list(...), class='Abline')
  }
  
  storeTemp(Points)
  storeTemp(Curve)
  storeTemp(Abline)
  
  storeTemp(c(1,2,3,4,16,17,5,6,15,18,19),'pch.to.use')

  ticks <- match.arg(ticks)
  if(missing(ticks)) {
    if(!missing(xlim)) ticks <- 'x'
    if(!missing(ylim)) ticks <- 'y'
    if(!missing(xlim) && !missing(ylim)) ticks <- 'xy'
  }
  plot(xlim, ylim, xlim=xlim, ylim=ylim, xlab=xlab, ylab=ylab,
       type='n', axes=ticks=='xy')

  switch(ticks,
         none = {axis(1, at=xlim, labels=FALSE)
                 axis(2, at=ylim, labels=FALSE)},
         x    = {axis(1)
                 axis(2, at=ylim, labels=FALSE)},
         y    = {axis(1, at=xlim, labels=FALSE)
                 axis(2)},
         xy   = )

  W <- list(...)
  m <- length(W)
  type <- label <- rep('', m)
  lty <- lwd <- pch <- cex <- rep(NA, m)
  curves <- vector('list', m)
  i <- 0
  for(j in 1:m) {
    w <- W[[j]]
    if(attr(w,'class')=='Abline') next
    i <- i + 1
    isfun <- is.function(w$type)
    curves[[i]] <- if(!key || isfun) w$points else
    switch(w$type,
           step = approx(w$points,
             xout=seq(min(w$points$x),max(w$points$x),length=50),
             method='constant', f=0),
           linear = approx(w$points,
             xout=seq(min(w$points$x),max(w$points$x),length=50)),
           w$points)
    label[i] <- w$label
    type[i] <- if(isfun) 'l' else switch(w$type, p='p', r='r', step='s', 'l')
    if(type[i]=='p') {
      pch[i] <- w$pch
      cex[i] <- w$cex
    } else if(type[i] != 'r') {  ## if( ) 12dec02
      lty[i] <- w$lty
      lwd[i] <- w$lwd
    }
  }
  if(i < m) {
    curves <- curves[1:i]
    label  <- label[1:i]
    type   <- type[1:i]
    lty    <- lty[1:i]
    lwd    <- lwd[1:i]
    pch    <- pch[1:i]
    cex    <- cex[1:i]
  }
  keyloc <- NULL
  j <- type!='r'
  if(any(j)) {   ## 12dec02
    if(!key)
      labcurve(curves[j], labels=label[j], type=type[j],
               lty=lty[j], lwd=lwd[j], opts=opts) else {
                 x <- unlist(lapply(curves, function(z)z$x))
                 y <- unlist(lapply(curves, function(z)z$y))
                 keyloc <- putKeyEmpty(x, y, labels=label[j], type=type[j],
                                       pch=pch[j], lty=lty[j],
                                       lwd=lwd[j], cex=cex[j])
               }
  }

  structure(list(W, xlab=xlab, ylab=ylab, xlim=xlim, ylim=ylim,
                 ticks=ticks, key=key, keyloc=keyloc, opts=opts),
            class='drawPlot')
}

bezier <- function(x, y, xlim, evaluation=100) {
  if(missing(y)) {
    y <- x[[2]]
    x <- x[[1]]
  }
  n <- length(x)
  X <- Y <- single(evaluation)
  Z <- seq(0, 1, length=evaluation)
  X[1] <- x[1]; X[evaluation] <- x[n]
  Y[1] <- y[1]; Y[evaluation] <- y[n]
  for(i in 2:(evaluation-1)) {
    z <- Z[i]
    xz <- yz <- 0
    const <- (1 - z)^(n-1)
    for(j in 0:(n-1)) {
      xz <- xz + const*x[j+1]
      yz <- yz + const*y[j+1]
      const <- const* (n-1-j)/(j+1) * z/(1-z)
      if(is.na(const))prn(c(i,j,z))
    }
    X[i] <- xz; Y[i] <- yz
  }
  list(x=as.single(X), y=as.single(Y))
}

plot.drawPlot <- function(x, file, xlab, ylab, ticks,
                          key=x$key, keyloc=x$keyloc, ...) {
  if(missing(xlab)) xlab <- x$xlab
  if(missing(ylab)) ylab <- x$ylab
  xlim <- x$xlim
  ylim <- x$ylim
  if(missing(ticks)) ticks <- x$ticks

  if(!missing(file)) setps(file, type='char', ...)

  plot(xlim, ylim, xlim=xlim, ylim=ylim, xlab=xlab, ylab=ylab,
       type='n', axes=ticks=='xy')
  switch(ticks,
         none = {axis(1, at=xlim, labels=FALSE)
                 axis(2, at=ylim, labels=FALSE)},
         x    = {axis(1)
                 axis(2, at=ylim, labels=FALSE)},
         y    = {axis(1, at=xlim, labels=FALSE)
                 axis(2)},
         xy   = )

  data <- x[[1]]
  m <- length(data)
  type <- label <- rep('', m)
  lty <- lwd <- pch <- cex <- rep(NA, m)
  curves <- vector('list', m)
  i <- 0
  for(j in 1:m) {
    w <- data[[j]]
    if(attr(w, 'class') == 'Abline') {
      do.call("abline", oldUnclass(w))
      next
    }
    i <- i + 1
    if(is.function(w$type)) w$type <- 'l'
    curves[[i]] <- if(!key) w$points else
    switch(w$type,
           step = approx(w$points,
             xout=seq(min(w$points$x),max(w$points$x),length=50),
             method='constant', f=0),
           linear = approx(w$points,
             xout=seq(min(w$points$x),max(w$points$x),length=50)),
           w$points)
    label[i] <- w$label
    switch(attr(w, 'class'),
           Points = {
             type[i] <- w$type
             pch[i] <- w$pch
             cex[i] <- w$cex
             switch(w$type,
                    p = points(w$points, cex=w$cex, pch=w$pch),
                    r = scat1d(w$points$x, side=1))
             switch(w$rug,
                    x = scat1d(w$points$x, side=1),
                    y = scat1d(w$points$y, side=2),
                    xy = {scat1d(w$points$x, side=1)
                          scat1d(w$points$y, side=2)},
                    none = )
           },
           Curve = {
             type[i] <- if(w$type=='step')'s' else 'l'
             lty[i] <- w$lty
             lwd[i] <- w$lwd
             lines(w$points, lty=w$lty, lwd=w$lwd, type=type[i])
           })
  }

  if(i < m) {
    curves <- curves[1:i]
    label  <- label[1:i]
    type   <- type[1:i]
    pch    <- pch[1:i]
    lty    <- lty[1:i]
    lwd    <- lwd[1:i]
    cex    <- cex[1:i]
  }
    
  if(key && !length(keyloc))
    stop('you may not specify key=T unless key=T was specified to drawPlot or keyloc is specified to plot')

  if(any(label!='')) {
    j <- type!='r'
    if(any(j)) {  ## 12dec02
      if(key) putKey(keyloc, labels=label[j],
                     type=type[j], pch=pch[j],
                     lty=lty[j], lwd=lwd[j], cex=cex[j]) else
      labcurve(curves[j], type=type[j],
               lty=lty[j], lwd=lwd[j], labels=label[j], opts=x$opts)
    }
  }                
  if(!missing(file)) {
    dev.off()
    cat('\nCreated file ',file,'.ps\n',sep='')
  }
  invisible()
}

