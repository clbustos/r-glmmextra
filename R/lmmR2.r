#' Calculates several measures of fit for Linear Mixel Models
#' based on Lou and Azen (2013) text.
#' Models could be lmer or lme models
#' @param m.null Null model (only with random intercept effects)
#' @param m.full Full model 
#' @return lmmR2 class
#' @export
lmmR2<-function(m.null, m.full) {
	if(is(m.null,"lme"))	 {
		return(lmmR2.lme(m.null,m.full))
	} else if (class(m.null)=="mer") {
		return(lmmR2.mer(m.null,m.full))
	} else {
		stop("Not implemented for other classes than lme or lmer") 
	}
}

# Calcula los cuatro R^2 presentes en el texto de Lou y Azen (2013).
# Debo extraer los interceptos para los modelos
lmmR2.mer<-function(m.null,m.full) {
	# Primero, verifico que tengan la misma estructura de grupos. Si 
	# no, estoy puro leseando
	v.0<-lme4::VarCorr(m.null)
	v.1<-lme4::VarCorr(m.full)
	if(!all.equal(names(v.0),names(v.1))) {
		stop("Groups should be equal")
	}
	n.b<-length(names(v.0))
	# recojo los sigmas
	sigmas=c(sigma(m.null)^2,sigma(m.full)^2)
	# recojo los thetas
	thetas.0=sapply(v.0,function(x) {x[1,1]})
	thetas.1=sapply(v.1,function(x) {x[1,1]})
	# recojo el largo promedio
	nn=sapply(m.null@flist,function(x) {
		length(levels(x)) / sum(1/table(x))
	})
	rb.r2.1<-1-(sigmas[2]/sigmas[1])
	rb.r2.2<-1-(sum(thetas.1)/sum(thetas.0))
	sb.r2.1<-1-((sigmas[2]+sum(thetas.1))/(sigmas[1]+sum(thetas.0)))
	sb.r2.2<-1-(  sigmas[2]+sum(thetas.1*nn)) / (sigmas[1]+sum(thetas.0*nn))
	out<-list(sigmas=sigmas,t0=thetas.0,t1=thetas.1, nn=nn, rb.r2.1=rb.r2.1, rb.r2.2=rb.r2.2, sb.r2.1=sb.r2.1, sb.r2.2=sb.r2.2)
	class(out)<-"lmmR2"
	out
}
# Extractor de varianzas para nlme
vars.lme<-function(x) {
	vv<-nlme::VarCorr(x)
	# Si tiene solo dos filas, recoge un solo factor
	if(nrow(vv)==2) {
		out=list()
		out[[colnames(x$groups)]]=as.numeric(vv[1,1])
		return(out)
	} else {
		out=list()
		vv.n<-rownames(vv)
		current.var=NULL
		for(i in 1:nrow(vv)) {
			c.name=vv.n[i]
			#print(vv.n[i])
			aa=grep("(.+) =",c.name,value=T)
			if(length(aa)) {
				aa=sub(" =","",aa)
				current.var=aa
			} else if(!is.null(current.var) & c.name=="(Intercept)") {
				out[[current.var]]=vv[i,1]
			}
		}
		out
	}
}
# Debo extraer los interceptos para los modelos
lmmR2.lme<-function(m.null,m.full) {
	# Primero, verifico que tengan la misma estructura de grupos. Si 
	# no, estoy puro leseando
	v.0<-vars.lme(m.null)
	v.1<-vars.lme(m.full)
	if(!all.equal(names(v.0),names(v.1))) {
		stop("Groups should be equal")
	}

	n.b<-length(names(v.0))
	# recojo los sigmas
	sigmas=c(m.null$sigma^2,m.full$sigma^2)
	# recojo los thetas
	thetas.0=sapply(v.0,function(x) {as.numeric(x[1])})
	thetas.1=sapply(v.1,function(x) {as.numeric(x[1])})
	#print(thetas.0)
	#print(thetas.1)
	# recojo el largo promedio
	nn=sapply(m.null$groups,function(x) {
		length(levels(x)) / sum(1/table(x))
	})
	
	rb.r2.1<-1-(sigmas[2]/sigmas[1])
	rb.r2.2<-1-(sum(thetas.1)/sum(thetas.0))
	sb.r2.1<-1-((sigmas[2]+sum(thetas.1))/(sigmas[1]+sum(thetas.0)))
	sb.r2.2<-1-(  sigmas[2]+sum(thetas.1*nn)) / (sigmas[1]+sum(thetas.0*nn))
	out<-list(sigmas=sigmas,t0=thetas.0,t1=thetas.1, nn=nn,rb.r2.1=rb.r2.1, rb.r2.2=rb.r2.2, sb.r2.1=sb.r2.1, sb.r2.2=sb.r2.2)
	class(out)<-"lmmR2"
	out
}

#' @export
print.lmmR2<-function(x) {
	summary.lmmR2(x)
}

#' @export
print.summary.lmmR2<-function(xx) {
	cat("Explanatory power of Multilevel Model\n")
	cat("=====================================\n")
	cat("Variances:\n")
	print(xx$m1)
	cat("Indexes:\n")
	print(xx$m2,row.names=F)
	cat("\n")
	
}

#' @export
summary.lmmR2<-function(x) {
	m1<-data.frame(avg.size=c(1,x$nn),null=c(x$sigmas[1],x$t0),full=c(x$sigmas[2],x$t1))
	#cat("Variances:\n")
	rownames(m1)[1]<-"Residual"
	#print(m1)
	#cat("Indexes:\n")
	m2<-with(x, data.frame(indexes=c("R & B R1","R & B R2","S & B R1","S & B R2"), 
	meaning=c("Within-cluster variance(relative)",
	"Between-cluster variance(relative)",
	"Reduce individual error(total)",
	"Reduce cluster error(total)"
	),
	vals=c(rb.r2.1,rb.r2.2,sb.r2.1,sb.r2.2)))
	#print(m2, row.names=F)
	out=list(m1=m1,m2=m2)
	
	class(out)<-"summary.lmmR2"
	return(out)
}
