plugins {
    kotlin("jvm") version "1.9.21"
    id("io.gitlab.arturbosch.detekt") version "1.23.6"
    id("org.jetbrains.kotlinx.kover") version "0.7.6"
    id("org.jetbrains.compose") version "1.5.12"
}

import org.jetbrains.compose.ExperimentalComposeLibrary

group = "com.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
    maven("https://maven.pkg.jetbrains.space/public/p/compose/interactive")
}

dependencies {
    implementation(compose.desktop.currentOs)

    // JLine 3 - Terminal support
    implementation("org.jline:jline-terminal:3.26.3")
    implementation("org.jline:jline-reader:3.26.3")
    implementation("org.jline:jline-terminal-jni:3.26.3")

    // Logging (required by JLine)
    implementation("org.slf4j:slf4j-api:2.0.9")

    // Coroutines for thread safety
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-swing:1.7.3")

    testImplementation(kotlin("test"))
    @OptIn(ExperimentalComposeLibrary::class)
    testImplementation(compose.desktop.uiTestJUnit4)
    testImplementation("org.junit.vintage:junit-vintage-engine:5.10.0")
}

compose.desktop {
    application {
        mainClass = "com.example.MainKt"
    }
}

tasks.test {
    useJUnitPlatform()
}

kotlin {
    jvmToolchain(17)
}

detekt {
    buildUponDefaultConfig = true
    allRules = false
    config.setFrom(files("$projectDir/detekt.yml"))
}

koverReport {
    defaults {
        filters {
            excludes {
                classes("*Main*")
                classes("*terminal*")
            }
        }
verify {
                rule("Basic Line Coverage") {
                    isEnabled = true
                    bound {
                        minValue = 95
                    }
                }
            }
    }
}

// Ensure proper pipeline order when running 'verify' or 'check'
tasks.named("check") {
    dependsOn("detekt", "test", "koverVerify")
}
tasks.named("test") {
    mustRunAfter("detekt")
}
tasks.named("koverVerify") {
    mustRunAfter("test")
}

tasks.register("verify") {
    group = "verification"
    description = "Runs the sequential verification pipeline: detekt -> test -> koverVerify"
    dependsOn("check")
}