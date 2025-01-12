--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Control.Monad
import Data.Function
import Data.List
import Data.Time.Calendar.OrdinalDate
import Data.Time.Clock
import Data.Time.Format
import Hakyll

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
  match "css/*" $ do
    route idRoute
    compile compressCssCompiler

  match "js/*" $ do
    route idRoute
    compile copyFileCompiler

  match "posts/*" $ do
    route $ setExtension "html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/post.html" postCtx
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls

  match "pages/archive.md" $
    compileMarkdownPage $
      (defaultContext <>) . listField "years" defaultContext $ do
        -- Load all posts and pair each one with the year it was published
        posts <- recentFirst =<< loadAll "posts/*"
        withYear <- forM posts $ \post -> do
          date <- getItemUTC defaultTimeLocale (itemIdentifier post)
          return (fst $ toOrdinalDate $ utctDay date, post)

        -- Group all posts with the same year
        let groupedPosts = groupBy ((==) `on` fst) withYear

        -- For each group, create a context with all the posts and run
        -- it through the year template
        forM groupedPosts $ \group ->
          let (year : _, posts) = unzip group
              yearCtx =
                defaultContext
                  <> constField "year" (show year)
                  <> listField "posts" postCtx (return posts)
           in makeItem "" >>= loadAndApplyTemplate "templates/postyear.html" yearCtx

  match "pages/index.md" $
    compileMarkdownPage $
      let posts = take 3 <$> (recentFirst =<< loadAll "posts/*")
       in defaultContext <> listField "posts" postCtx posts

  match "templates/*" $ compile templateBodyCompiler

--------------------------------------------------------------------------------
compileMarkdownPage :: Context String -> Rules ()
compileMarkdownPage ctx = do
  route $ gsubRoute "pages/" (const "") `composeRoutes` setExtension "html"
  compile $
    getResourceBody
      >>= applyAsTemplate ctx
      >>= renderPandoc
      >>= loadAndApplyTemplate "templates/default.html" defaultContext
      >>= relativizeUrls

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y"
    <> defaultContext
