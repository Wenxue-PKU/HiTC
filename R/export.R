###################################
## exportC
##
## Export HiTC object to standard format
##
## x = an object of class HTCexp
## con = basename of files to create
##
###################################

writeC <- function(data2export, xgi, ygi, file, genome="mm9", header=FALSE, use.names=TRUE, rm.na=TRUE){
    message("Export genomic ranges as BED files ...")

    ## Use names
    if (!use.names){
        rownames(data2export) <- 1:nrow(data2export)
        colnames(data2export) <- 1:ncol(data2export)
        elementMetadata(xgi)$name <- 1:length(xgi)
        if (!is.null(ygi)){
            elementMetadata(ygi)$name <- 1:length(ygi)
        }
    }
    
    ## Remove NA
    if (rm.na){
        data2export[Matrix::which(is.na(data2export))] <- 0
    }
    
    ## Write header and BED files
    bed.xgi <- paste(file,"_xgi.bed", sep="")
    if (header){
        write(paste("##HiTC - v", packageVersion("HiTC"), sep=""),file=bed.xgi)
        write(paste("##",date(), sep=""),file=bed.xgi, append=TRUE)
        rtracklayer::export(xgi, con=paste(file,"_xgi.bed", sep=""), format="bed", append=TRUE)
    }else{
        rtracklayer::export(xgi, con=paste(file,"_xgi.bed", sep=""), format="bed", append=FALSE)
    }  

    if(!is.null(ygi)){
        bed.ygi <- paste(file,"_ygi.bed", sep="")  
        if (header){
            write(paste("##HiTC - v", packageVersion("HiTC"), sep=""),file=bed.ygi)
            write(paste("##",date(), sep=""),file=bed.ygi, append=TRUE)
            rtracklayer::export(ygi, con=paste(file,"_ygi.bed", sep=""), format="bed", append=TRUE)
        }else{
            rtracklayer::export(ygi, con=paste(file,"_ygi.bed", sep=""), format="bed", append=FALSE)
        }
    }
    
    ## Export map
    count.out <- paste(file,".mat", sep="")
    message("Export interaction map in '",count.out,"' ...")
    data2export <- as(data2export, "TsparseMatrix")
    
    if (header){
        write(paste("##HiTC - v", packageVersion("HiTC"), sep=""),file=count.out)
        write(paste("##",date(), sep=""),file=count.out, append=TRUE)
        write(paste(rownames(data2export)[data2export@i+1], colnames(data2export)[data2export@j+1], data2export@x, sep="\t"), file=count.out, append=TRUE)
    }else{
        write(paste(rownames(data2export)[data2export@i+1], colnames(data2export)[data2export@j+1], data2export@x, sep="\t"), file=count.out, append=FALSE)
    }
    invisible(NULL)
}
    


exportC <- function(x, file, per.chromosome=FALSE, use.names=FALSE, header=FALSE){
    if (inherits(x, "HTCexp")){
        ##stopifnot(isSymmetric(x))
        data2export <- intdata(x)
        xgi <- x_intervals(x)
        if(!isSymmetric(x))
            ygi <- y_intervals(x)
        else
            ygi <- NULL
        writeC(data2export, xgi, ygi, file, header=header, use.names=use.names)
    }else if (inherits(x, "HTClist")){
        if (per.chromosome){
            lapply(x, function(xx){
                data2export <- intdata(xx)
                xgi <- x_intervals(xx)
                if(!isSymmetric(xx))
                    ygi <- y_intervals(xx)
                else
                    ygi <- NULL
                chrname <- paste0(seqlevels(xx), collapse="")
                writeC(data2export, xgi, ygi, file=paste0(file, "_", chrname), header=header, use.names=use.names)
            })
        }else{
            if (isComplete(x)){
                data2export <- getCombinedContacts(x)
                combi <- getCombinedIntervals(x)
                writeC(data2export, combi$xgi, combi$ygi, file, use.names=use.names, header=header)
            }else{
                stop("isComplete(x) is not TRUE. Cannot export incomplete HTClist object as one file. Please use per.chromosome=TRUE.")
            }
        }
    }
    invisible(NULL)
}##exportC


###################################
## export.my5C
##
## Export HiTC object to my5C
##
## x = an object of class HTCexp
## file = name of file to create
##
###################################

write.my5C <- function(data2export, xgi, ygi, file, genome="mm9", header=TRUE){

    file <- paste0(file, ".mat")
    if (header){
        write(paste0("##HiTC - v", packageVersion("HiTC")),file=file)
        write(paste0("##",date()),file=file, append=TRUE)
        write("##my5C export matrix format",file=file, append=TRUE)
    }

    xnames <- paste(id(xgi),"|",genome,"|",seqnames(xgi),":",start(xgi),"-",end(xgi), sep="")
    ynames <- paste(id(ygi),"|",genome,"|",seqnames(ygi),":",start(ygi),"-",end(ygi), sep="")
    colnames(data2export) <- xnames
    rownames(data2export) <- ynames

    message("Exporting data in '",file,"' ...")
    suppressWarnings(write.table(as.data.frame(as.matrix(data2export)), file=file, quote=FALSE, sep="\t", append=TRUE))
}##write.my5C
    
export.my5C <- function(x, file, genome="mm9", per.chromosome=FALSE){
    if (inherits(x, "HTCexp")){
        ##stopifnot(isSymmetric(x))
        data2export <- intdata(x)
        xgi <- x_intervals(x)
        ygi <- y_intervals(x)
        write.my5C(data2export, xgi, ygi, genome=genome, file=file)
      
    }else if (inherits(x, "HTClist")){
        if (per.chromosome){
            lapply(x, function(xx){
                data2export <- intdata(xx)
                xgi <- x_intervals(xx)
                ygi <- y_intervals(xx)
                chrname <- paste0(seqlevels(xx), collapse="")
                write.my5C(data2export, xgi, ygi, file=paste0(file, "_", chrname))
            })
        }else{
            if (isComplete(x)){
                data2export <- getCombinedContacts(x)
                combi <- getCombinedIntervals(x)
                ygi <- combi$ygi
                if (!is.null(combi$xgi))
                    xgi <- combi$xgi
                else
                    xgi <- ygi
                write.my5C(data2export, xgi, ygi, file=paste0(file, "_", genome))
            }else{
                stop("isComplete(x) is not TRUE. Cannot export incomplete HTClist object as one file. Please use per.chromosome=TRUE.")
            }
        }
    }
    invisible(NULL)
}##export.my5C

###################################
## saveContactMaps
##
## Export HiTC object in images at the good resolution
##
## x = an object of class HTCexp
## con = output file name or prefix
##
###################################

saveContactMaps <- function(x, con, device="pdf", per.chrom=FALSE, ...)
{
  stopifnot(!missing(con))

  if (length(grep(".pdf$", con)) != 0)
    device <- "pdf"
  else if (length(grep(".png$", con)) != 0)
    device <- "png"

  if (device == "pdf")
    dFun <- pdf
  else if (device == "png")
    dFun <- png
  else
    stop("Unsupported device")

  minres <- 680
  if(inherits(x,"HTCexp")){
    d <- dim(intdata(x))
    if (d[1] < minres || d[2] < minres){d <- c(minres, minres)}
    dFun(con,  width=d[1], height=d[2])
    mapC(x, ...)
    dev.off()
  }else if(inherits(x,"HTClist")){
    if (per.chrom==TRUE){
      if (device == "pdf"){
        dFun(con)
        lapply(x, function(xx){
          d <- dim(intdata(xx))
          if (d[1] < minres || d[2] < minres){d <- c(minres, minres)}
          pdf.options(width=d[1], height=d[2])
          mapC(HTClist(xx), ...)
        })
        dev.off()
      }else if (device=="png"){
        lapply(x, function(xx){
          d <- dim(intdata(xx))
          if (d[1] < minres || d[2] < minres){d=c(minres, minres)}
          dFun(paste0(sub(".png$","",con), "_", paste0(seqlevels(xx), collapse=""), ".png"),  width=d[1], height=d[2])
          mapC(HTClist(xx), ...)
          dev.off()
        })
      }
    }else{
      dFun(con,  width=1200, height=1200)
      mapC(x, ...)
      dev.off()
    }
  }
}
